# Driver location tracking

A small Flutter app for the driver-tracking assessment. It starts and stops a location stream, stores every point on the phone, and uploads pending points to a mock API when the network is available. A failed upload stays pending and is retried. Each point has one id, so a retry cannot create a second point on the server.

GPS is simulated. The mock API lives in the app process, so there is no server to run.

## Run

```bash
flutter pub get
flutter test
flutter run
```

Use an Android emulator or a device. The route is simulated, so a GPS fix is not required.

## Try the offline flow

1. Press **Start**. A point is saved about every 3 seconds and, while you are online, marked **Synced**.
2. Turn on **Simulate offline** and leave tracking on. New rows stay **Pending**. They are in SQLite, so they are still there after a restart.
3. Stop the app, open it again, then turn **Simulate offline** off. Pending rows upload on startup, or as soon as the switch goes off.
4. Turn on **Fail uploads**. The mock rejects the next posts, the failed count on that row goes up, and the app retries every few seconds. Turn the switch off and the same rows upload. They are not sent again after they are synced.

The offline switch is a stand-in for airplane mode, so the sync path can be shown without changing the emulator network.

## Layout

```
lib/
  main.dart                          wires the objects and starts the cubit
  ui/tracking_page.dart              start, stop, status, list
  tracking/tracking_cubit.dart       session, connectivity, retry timer
  data/location_repository.dart      save a fix, flush pending rows
  data/location_store.dart           SQLite
  data/location_api.dart             mock POST /driver/locations
  data/connectivity_monitor.dart     real connectivity, plus the demo override
  location/simulated_location_source.dart
```

UI talks to `TrackingCubit`. The cubit talks to `LocationRepository`. The repository is the only type that sees both the store and the API. Tests use the same repository and store, with connectivity and the API faked.

State is a Cubit rather than a full Bloc. The screen has a handful of actions (start, stop, two demo switches), and a Cubit keeps that obvious.

## Decisions

**Local first.** A point is inserted before any upload is attempted. If the process dies after the insert, the row is still pending and the next launch tries again.

**One id per capture.** The id is assigned in `LocationRepository.saveFix` and stored on the row. Retries send that same id. `MockLocationApi` keeps a set of accepted ids and treats a repeat as success, not as a new point. After a row is marked synced, `pending()` no longer returns it, so the client does not submit it again.

**One flush at a time.** `syncPending` will not upload the same batch on two overlapping calls. If a new point is saved while a flush is running, that flush runs another pass instead of starting a second one.

**Stop on the first failure.** The batch is oldest-first. If a post fails, the attempt count for that row is incremented and the rest of the batch waits. That keeps trip order, and it avoids hammering a server that is already failing. The cubit schedules another flush a few seconds later while the app is online. Opening the app also flushes.

**SQLite.** Pending and synced rows survive a process restart. The store is an interface; the tests open a real database file in a temp directory, close it, and open it again.

**Simulated fixes.** `LocationSource` is the only seam the tracker needs. `SimulatedLocationSource` walks a short route around India Gate. A device build would replace that class with one that listens to the platform location API and emits the same `GeoFix`. Nothing above the source would change.

## Tests

`flutter test` covers two paths:

- A point saved while offline is still in the database after the connection is closed and opened again, and a new cubit uploads it once.
- The first upload fails and leaves the row pending with an attempt count of 1. The next flush succeeds. A later flush does not post that id again. Posting the same id to the mock API still leaves a single accepted record.

## Background tracking

Continuous tracking while the UI is gone is not implemented here. This is how I would add it, and where the operating system will not cooperate.

The queue above stays the same. A background component should write the same `locations` rows the screen already reads. Sync stays "flush pending rows when there is a path", whether the caller is the cubit, a connectivity callback, or a background isolate.

**Minimized or screen locked**

On Android, run a foreground service with a persistent notification and `foregroundServiceType="location"` (required on Android 14). Hold `ACCESS_FINE_LOCATION` and `ACCESS_BACKGROUND_LOCATION`. From Android 10 the background grant is separate, and from Android 11 the system usually sends the user to Settings for it. Doze can defer normal background work; a foreground location service is the supported way to keep getting fixes with the screen off. `WorkManager` fits the upload queue, not a stream of GPS points.

On iOS, turn on Background Modes → Location updates and request Always authorization (`NSLocationWhenInUseUsageDescription` and `NSLocationAlwaysAndWhenInUseUsageDescription`). "While Using" stops being enough once the app is suspended. Set `allowsBackgroundLocationUpdates` and, for an active trip, `pausesLocationUpdatesAutomatically = false`, or iOS will pause the stream when it decides the device is idle. The system location indicator stays visible. That is expected.

**Network drops**

Location updates do not depend on the radio. Keep appending rows. Upload when connectivity comes back, using the same id so a retry that the server already stored is ignored. The sample already does this part in the foreground.

**Process killed by the system**

Android can restore a sticky foreground service after a low-memory kill. On that restart the Flutter UI isolate is not running, so the service (or a background isolate started from it) has to open the same database and keep writing. iOS may suspend the app; with the location background mode it will wake it to deliver updates. Neither of those is a force-quit.

**Force-closed**

If the driver force-stops the app on Android, the system will not restart the service, and a boot receiver will not run either, until the driver opens the app again. Some OEM skins also kill background work unless battery optimization is disabled for the app. The in-trip notification should stay up so the driver does not swipe it away, and the app should explain that swipe.

If the driver removes the app from the iOS app switcher, continuous updates stop. iOS will not relaunch the app to keep a high-accuracy stream. Significant-change and region monitoring can relaunch a terminated app, but they are too coarse for a live trace. For a public iOS app I would not promise tracking after a force quit. A managed Android device (device owner / lock task) is the usual way fleets stop the driver from killing the process. There is no equivalent for a normal App Store build.

A production driver app would use the platform location API behind `LocationSource`, plus a small Android foreground service. I would not try to keep a `Timer` inside a widget alive in the background.
