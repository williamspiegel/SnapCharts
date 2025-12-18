# Instructions for running SnapCharts

The project has been successfully set up and built via the command line. If you are seeing errors like `No such module 'DGCharts'` in Xcode, please follow these steps:

1.  **Close Xcode completely.**
2.  **Open the Workspace:**
    *   Navigate to the project folder.
    *   Double-click on **`SnapCharts.xcworkspace`** (white icon).
    *   **Do NOT** open `SnapCharts.xcodeproj` (blue icon). CocoaPods requires the workspace to link libraries like `DGCharts`.

3.  **Select a Simulator:**
    *   In the top-left of Xcode, click the device/simulator selector (next to the play button).
    *   Select a specific simulator like **iPhone 16** (or any iOS Simulator).
    *   Do **NOT** select "My Mac (Designed for iPhone/iPad)" if possible, as it can sometimes cause architecture issues during development.

4.  **Clean and Build:**
    *   Go to **Product > Clean Build Folder** (or press `Cmd + Shift + K`).
    *   Wait for the clean to finish.
    *   Run the app by pressing the **Play** button (or `Cmd + R`).

5.  **API Keys:**
    *   The project now uses Yahoo Finance API, so no API keys are required for basic usage.

The "No such module" error usually appears because the editor index is stale or the wrong file (project vs workspace) is opened. The build system itself is working correctly.
