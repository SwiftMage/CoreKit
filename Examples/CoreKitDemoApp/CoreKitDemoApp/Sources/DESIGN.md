# CoreKitDemoApp Design Document

This document outlines the architecture, modules, and features of the CoreKitDemoApp.

## Architecture Overview

(To be defined - e.g., MVVM, TCA)

## Modules

*(List major components/modules of the app)*

-   **App:** Main application entry point (`CoreKitDemoAppApp.swift`).
-   **Views:** SwiftUI views, organized by feature.
    -   **Onboarding:** Views related to the user onboarding flow.
        -   `DemoOnboardingSteps.swift`: Defines content for individual onboarding steps.
        -   `OnboardingContainerView.swift`: Manages the display and navigation of onboarding steps.
-   **ViewModels:** (If applicable)
-   **Models:** Data models used throughout the application.
-   **Services:** Business logic, networking, persistence.
-   **Utilities:** Helper functions, extensions, constants.
-   **Resources:** Assets, localization files, fonts.

## Implemented Features

*(List key features implemented so far)*

-   **Onboarding Flow:** A multi-step introduction for new users, guiding them through initial setup or app features.
    -   Displays content defined in `DemoOnboardingSteps`.
    -   Provides navigation (Previous/Next/Finish) via `OnboardingContainerView`.

## Project Structure

(Describe the folder organization, following the initial guidelines if applicable)

```
CoreKitDemoApp/
|-- Sources/
|   |-- App/
|   |   `-- CoreKitDemoAppApp.swift
|   |-- Views/
|   |   `-- Onboarding/
|   |       |-- DemoOnboardingSteps.swift
|   |       `-- OnboardingContainerView.swift
|   |-- Models/
|   |-- ViewModels/
|   |-- Services/
|   |-- Utilities/
|-- Resources/
|-- Tests/
|-- DESIGN.md
|-- TASKS.md 
|-- ... (Other project files like .xcodeproj)
``` 