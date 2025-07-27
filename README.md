# Omarchy (Apple Silicon Fork)

This is a fork of the [Omarchy](https://omarchy.org) project, specifically modified to provide a fully-configured, beautiful, and modern web development system based on Hyprland for Apple Silicon MacBooks running **Asahi Arch Linux Minimal**.

Our goal is to ensure a seamless and optimized experience on this platform, addressing hardware-specific considerations. We have thoroughly reviewed and adjusted the package selection to ensure compatibility and a smooth, interactive setup on aarch64 architectures.

## Key Modifications for Apple Silicon

To enhance compatibility and functionality on Apple Silicon MacBooks with Asahi Arch Linux Minimal, the following significant changes have been implemented:

*   **Asahi Bootloader Integration:** Added support for the Asahi Linux bootloader, ensuring proper system initialization.
*   **Conditional Driver Management:** Disabled NVIDIA driver installation and `asdcontrol` utility for `aarch64` architectures, as these are not applicable or supported on Apple Silicon.
*   **Enhanced Display Brightness Control:** Implemented `brightnessctl` for robust display brightness adjustment, replacing `asdcontrol` and updating relevant keybindings.
*   **Improved Keyboard Layout Detection:** Enhanced the installation process to offer a "Macintosh (US)" keyboard layout option, catering to typical macOS user preferences.
*   **Natural Touchpad Scrolling:** Configured the touchpad for natural scrolling, aligning with the intuitive macOS user experience.
*   **Optimized Audio Configuration:** Ensured `pipewire-pulse` is installed to provide comprehensive audio functionality and PulseAudio compatibility.


## Apple Silicon Mac Support (Detailed)

*   **Webcam:** Webcam functionality is generally supported. For optimal image quality, you may need to copy the `appleh13camerad` calibration file from your macOS installation to your Asahi Linux system.
*   **Ambient Light Sensor:** The ambient light sensor is not currently supported. Automatic brightness adjustment based on ambient light will not function.

## License

Omarchy is released under the [MIT License](https://opensource.org/licenses/MIT).

