# Danswer - AI Homework Solver

**Danswer** (AI 作业助手) is a powerful Flutter application designed to help students solve homework problems using AI. It allows users to take photos of math problems (or other subjects), crop them, and get detailed step-by-step solutions from an AI tutor.

## ✨ Key Features

*   **📸 Snap & Solve**: Capture homework problems directly with your camera or pick from your gallery.
*   **✂️ Smart Cropping**: Built-in image cropper to focus exactly on the problem you need solving.
*   **🤖 AI-Powered Solutions**: Connects to OpenAI-compatible APIs (like GPT-4o) to provide accurate, detailed explanations.
*   **➗ LaTeX Support**: Beautifully renders mathematical formulas (both inline and block equations) for clear reading.
*   **💬 Interactive Follow-up**: Have a conversation with the AI about the solution. Ask for clarification or further explanation.
    *   **Quote to Ask**: Select specific text or formulas in the solution to ask targeted questions.
*   **📜 History Tracking**: Automatically saves your solved problems and conversation history for review.
*   **⚙️ Customizable Settings**:
    *   Configure API Key, Base URL, and Model Name.
    *   Customize the System Prompt to tailor the AI's teaching style.
*   **🌍 Multi-language Support**: Fully localized for English and Chinese (中文).

## 🚀 Getting Started

### Prerequisites

*   [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.10.0 or higher)
*   An API Key from OpenAI or a compatible provider (e.g., DeepSeek, Moonshot, etc.).

### Installation

1.  **Clone the repository**
    ```bash
    git clone https://github.com/yourusername/danswer.git
    cd danswer
    ```

2.  **Install dependencies**
    ```bash
    flutter pub get
    ```

3.  **Run the app**
    ```bash
    flutter run
    ```

## 🛠️ Configuration

Before using the AI features, you need to configure your API settings:

1.  Open the app and navigate to the **Settings** (gear icon) page.
2.  Enter your **API Key**.
3.  (Optional) Set a custom **Base URL** if you are using a proxy or a compatible service (default is OpenAI).
4.  (Optional) Change the **Model Name** (e.g., `gpt-4o`, `gpt-3.5-turbo`).
5.  Tap **Save**.

## 📱 Usage

1.  **Home Screen**: Tap the "Camera" button to take a photo or "Gallery" to pick an image.
2.  **Crop Screen**: Adjust the frame to cover the specific problem you want to solve. Tap the checkmark.
3.  **Result Screen**:
    *   Wait for the AI to analyze and solve the problem.
    *   Read the rendered solution with math formulas.
    *   **Follow-up**: Type in the chat bar to ask more questions.
    *   **Quote**: Long-press (or select) any text in the solution, tap **"Quote"** (or **"引用"**), and it will be added to your input box for context-aware questioning.
4.  **History**: Access your past problems from the Home screen history list.

## 🏗️ Tech Stack

*   **Framework**: [Flutter](https://flutter.dev/)
*   **State Management**: [Provider](https://pub.dev/packages/provider)
*   **Markdown & LaTeX**: `flutter_markdown`, `flutter_math_fork`
*   **Image Handling**: `image_picker`, `crop_image`, `photo_view`
*   **Storage**: `shared_preferences`, `path_provider`
*   **Networking**: `http`

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
