# Hora 🩺

**Hora** (meaning *Hour* or *Time*) is a premium, high-reliability clinical assistant and procedural timer application built with Flutter. It is designed specifically for healthcare professionals (such as doctors, nurses, and clinical staff) to track patient vitals, schedule ward duties, and monitor timed clinical procedures (e.g., IV infusions, nebulization, patient observations) with active background execution and persistent system-level alerts.

Featuring a modern, interactive **Liquid Glass (glassmorphic) interface** with smooth micro-animations, Hora ensures that vital information remains accessible and alerts are never missed.

---

## 🌟 Key Features

### 1. High-Reliability Procedural Timer
*   **Active Background Execution:** Powered by `flutter_background_service` and `flutter_local_notifications`, timers run continuously in a background thread even when the app is minimized, closed, or the screen is locked.
*   **Dual Alert Channels:** Support for customized alert configurations (Sound, Vibration, or Both). Includes standard medical alert sounds (Clinical Beep, Vital Alert, Emergency Pulse, IV Completion Blip).
*   **Custom Ringtone Support:** Allows importing and picking custom audio ringtone files via `file_picker`.
*   **Interval Alerts:** Schedule intermediate checks during long procedures (e.g., sound a soft blip every 5 minutes to prompt clinical assessments or record intermediate vitals).

### 2. Lock-Screen Alarm Overlay
*   **Immediate System Alerts:** Utilizing the `system_alert_window` overlay permission, a high-priority overlay window pops over any active application or locked screen upon timer completion.
*   **Unmissable Clinical Prompts:** Enforces patient-safety compliance by prompting the user to acknowledge the completed timer ("Timer Finished! Please check on your patient") and stop the alert.

### 3. Vitals & Patient Records Logging
*   **Pre-Timer Vitals Check:** Enforces recording of baseline patient data (Name, Age, Weight) and vital signs (SPO2 %, Blood Pressure) before commencing any clinical timer.
*   **Comprehensive Charts:** View patients list and log successive vitals records over time, capturing trends in SPO2, blood pressure, temperature, heart rate, and custom clinical notes.
*   **SQLite Storage:** Offline-first architecture powered by `sqflite` with automatic schema creation and relational mapping between Patients and Vitals (utilizing `ON DELETE CASCADE`).

### 4. Shift & Task Scheduler
*   **Upcoming Schedule & Reminders:** Plan shifts, surgery preps, medication rounds, and group meetings.
*   **Auto-Cleaning Temporary Tasks:** Support for both normal tasks and *Temporary Tasks* (e.g., daily checklists or short-term notes) that automatically expire and clean up from the local database after 7 days on startup.

### 5. Premium Liquid Glass UI
*   **Glassmorphic Aesthetic:** Beautiful visual design leveraging custom glass containers with backdrop filters, blur, opacity, and harmonized color palettes.
*   **Adaptive Theming:** Seamless dark mode and light mode toggles along with a curated "Liquid Glass" theme featuring smooth gradients.
*   **Immersive Micro-interactions:** Tactile vibration responses when adjusting sliders/pickers.

---

## 🏥 Clinical Use Cases & Scenarios

Hora is specifically tailored to fit the workflows of fast-paced hospital wards, clinics, and emergency units:

### 1. Intravenous (IV) Therapy & Infusion Monitoring
*   **The Scenario:** A nurse starts a drug infusion (e.g., antibiotics, chemotherapy, or electrolyte corrections) that needs to be checked or discontinued in 45 minutes.
*   **Hora Workflow:** The nurse sets a 45-minute timer. The app requires logging the patient's name, age, weight, and baseline vitals (SPO2, blood pressure). At the 45-minute mark, even if the nurse's phone is locked in their pocket, a persistent medical overlay triggers, requiring them to physically acknowledge the alert and attend to the patient.

### 2. Timed Patient Observations & Vitals Checks
*   **The Scenario:** Following the administration of a high-risk medication (e.g., insulin, blood pressure regulators, or narcotics), a physician requires monitoring the patient’s vitals every 15 minutes for 1 hour.
*   **Hora Workflow:** The doctor sets a 60-minute duration with a **15-minute interval alert**. Every 15 minutes, a distinct soft beep sounds, prompting the clinician to perform a quick check and log the intermediate vitals (SPO2, heart rate, BP) directly into the patient's profile in the database.

### 3. Oxygen & Nebulizer Treatment Cycles
*   **The Scenario:** A respiratory therapist starts a 20-minute nebulization cycle.
*   **Hora Workflow:** The therapist sets a 20-minute timer. Once the time is up, the screen overlay pops up, preventing the nebulizer from running dry or being left on the patient longer than intended.

### 4. Ward Round Coordinator & Task Handovers
*   **The Scenario:** Clinicians during shift handovers need to track transient tasks (e.g., "Check blood glucose for Bed 6 in 2 hours", "Follow up on lab tests at 2:00 PM").
*   **Hora Workflow:** Shift duties are scheduled as tasks. Normal tasks remain on the schedule, while quick, transient checks are registered as *Temporary Tasks* which automatically expire and are purged from the database after 7 days, maintaining a clean, clutter-free workspace.

---

## 🩺 Value & Utility in the Medical Field

*   **Combats Alert Fatigue:** Typical mobile alarms blend in with standard notification sounds. Hora's tailored medical audio alerts (such as *IV Completion Blip* and *Vital Alert*) and full-screen overlay ensure urgent clinical alerts stand out.
*   **Promotes Documentation Compliance:** By prompting clinicians for baseline patient vitals before starting a procedure timer, it integrates documentation into the clinical flow.
*   **Fully Offline & Secure (Local HIPAA Alignment):** Hora stores all logs in a local SQLite database (`hora_database.db`). Since there are no network transfers or cloud syncing, patient data is kept completely private and localized to the clinician's physical device.
*   **Eliminates OS Background Termination:** Most mobile operating systems kill background apps to save battery. Hora utilizes a persistent foreground Android service, guaranteeing that crucial clinical timers will not fail mid-procedure.

---

## 📂 Project Structure

The project follows a clean, feature-first architectural pattern:

```text
lib/
├── core/
│   ├── app_themes.dart     # Custom theme modes, palettes (Liquid Glass, Dark, Light)
│   └── db_helper.dart      # SQLite database configuration and CRUD queries
├── models/
│   ├── patient_model.dart  # Data structures for PatientModel & VitalsRecord
│   └── task_model.dart     # Data structures for TaskModel (Normal/Temporary tasks)
├── features/
│   ├── clinical/           # Patient profiles list, add patient, and vitals logger
│   ├── home/               # Navigation scaffold and clinical daily dashboard
│   ├── notifications/      # Local notification service configurations
│   ├── tasks/              # Task scheduler management screens and providers
│   └── timer/              # Foreground background services and active timer UI
├── widgets/
│   └── glass_container.dart # BackdropFilter glass container style utility
└── main.dart               # App entrypoint, Provider setup, and service init
```

---

## 🛠️ Tech Stack & Dependencies

*   **Framework:** Flutter (Dart SDK `^3.10.7`)
*   **State Management:** `provider` (MultiProvider context architecture)
*   **Local Storage:** `sqflite` & `path` (Relational SQL DB)
*   **Background Services:** `flutter_background_service` & `flutter_local_notifications`
*   **System Overlays:** `system_alert_window` (Overlay alert popup)
*   **Audio & Haptics:** `audioplayers` & `vibration`
*   **Utilities:** `uuid`, `intl`, `timezone`, `csv`, `file_picker`, `android_alarm_manager_plus`
*   **Design & Styling:** `google_fonts` (Outfit / Inter) & `flutter_staggered_animations`

---

## 🚀 Getting Started & Installation

### Prerequisites
*   [Flutter SDK](https://docs.flutter.dev/get-started/install) installed on your development machine.
*   An Android Device or Emulator (Android 6.0+ / API 23+ recommended for system alert overlays and foreground services).

### Setup Instructions

1.  **Clone the Repository:**
    ```bash
    git clone https://github.com/your-repo/hora.git
    cd hora
    ```

2.  **Install Dependencies:**
    Fetch the necessary packages listed in `pubspec.yaml`:
    ```bash
    flutter pub get
    ```

3.  **Android Configurations:**
    Make sure overlay and foreground service permissions are requested. The app automatically handles runtime requests for:
    *   `SYSTEM_ALERT_WINDOW` (Overlay draw-on-top permission)
    *   Notification & Vibration permissions

4.  **Run the Application:**
    Connect your device/emulator and run:
    ```bash
    flutter run
    ```

---

## 🔒 Permissions & Security

Because **Hora** is engineered for high-criticality medical tracking, it requires the following device permissions:
*   **Draw Over Other Apps (Overlay):** Used to display the urgent alert window when a timer ends while the user is using another app or has their screen locked.
*   **Foreground Service / Background Notifications:** Enables the timer to remain active and accurate when the application is minimized.
*   **Storage Access (File Picker):** Enables importing custom ringtones from internal storage.
*   **Vibration Control:** Provides physical haptic feedback alerts.
