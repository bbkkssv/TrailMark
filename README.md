# TrailMark

## App overview

TrailMark is a small trail journal app. It shows a today dashboard using HealthKit data, and it lets me save field journal memos as audio or video. Audio memos show a waveform, can be played back, and now show progress while playing.

## Feature checklist

Done

1. Today dashboard with steps, distance, calories, and flights climbed
2. HealthKit permission request
3. Audio recording
4. Video capture
5. Journal list for saved memos
6. Audio playback
7. Dynamic waveform for saved audio
8. Live waveform while recording
9. Playback progress marker on the waveform

Not done

1. Delete memos
2. Full location tagging
3. Photo library import flow
4. More detailed memo notes

## Architecture

The app is mostly MVVM style.

Services are in TrailMarkCore. HealthKitManager handles HealthKit, MediaStore handles saved media files, AudioRecorder handles recording, and AudioPlayer handles playback.

The ViewModel layer is AppModel. It owns the shared services and gives the SwiftUI screens one place to read and update app data.

Views are the SwiftUI files. ContentView sets up the tabs. TodayDashboardView shows the health summary. FieldJournalView shows the memo list. RecordAudioView handles recording UI. MemoDetailsView handles playback, waveform display, and memo details.

## Permissions handled

Health is handled through HealthKitManager.

Camera is handled through VideoCaptureView.

Photos are partially handled because VideoCaptureView falls back to the photo library when the simulator does not have a camera.

Location is not fully handled yet.

## Biggest challenge

The biggest challenge was making the waveform feel real instead of looking like a static icon. At first it was using peak values, which made the bars look too even and too loud. I fixed it by reading the actual audio file, sampling it with RMS loudness, adding a noise floor, and drawing a progress marker during playback.
