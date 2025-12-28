# Enhanced Timezone Detection and Configuration

## Overview

Omarchy now includes enhanced timezone detection and configuration options that address the issue where installation couldn't automatically set the correct timezone based on location.

## New Features

### 1. **Automatic Detection During Installation**
- **IP-based Geolocation**: Uses `tzupdate` to detect timezone from IP address
- **Hardware Clock Detection**: Attempts to detect from hardware clock settings
- **Fallback Handling**: Gracefully handles detection failures

### 2. **Interactive Setup Options**
- **Auto-detect with Confirmation**: Detects timezone and asks for confirmation
- **Manual Selection**: User-friendly interface for selecting timezone by region/city
- **Skip Option**: Allow users to keep current timezone if preferred

### 3. **First-Run Setup**
- **Smart Notifications**: Prompts users to configure timezone if still set to UTC
- **Internet-Aware**: Only offers auto-detection when internet is available
- **Non-intrusive**: Provides gentle reminders without blocking the user experience

### 4. **Enhanced User Interface**
- **Waybar Integration**: Left-click shows current timezone, right-click updates
- **Menu System**: Organized timezone options in the Omarchy menu
- **Modern UI**: Uses `gum` for better terminal interfaces when available

## Usage

### During Installation
The timezone detection runs automatically during the installation process in the configuration phase:
- Attempts automatic detection if internet is available
- Falls back to interactive selection if needed
- Continues with UTC if no user interaction is possible

### After Installation

#### Waybar Clock Integration
- **Left Click**: Show current timezone information
- **Right Click**: Auto-detect and update timezone

#### Menu System
Access via `omarchy-menu` → Update → Timezone:
- **Auto-detect**: Automatic timezone detection
- **Manual Selection**: Choose from organized timezone list
- **Show Current**: Display current timezone settings

#### Command Line
```bash
# Auto-detect timezone
omarchy-cmd-tzupdate-enhanced

# Manual selection interface
omarchy-cmd-tzupdate-enhanced manual

# Show current timezone info
omarchy-cmd-tzupdate-enhanced show

# Manual selection only
omarchy-cmd-tzupdate-manual
```

## Detection Methods

### 1. IP-based Geolocation
- Uses `tzupdate` package (automatically installed)
- Queries IP geolocation services
- Most accurate for typical use cases
- Requires internet connection

### 2. Hardware Clock Analysis
- Examines RTC (Real-Time Clock) settings
- Useful for dual-boot systems
- Limited accuracy but works offline

### 3. Interactive Selection
- Region-based selection (America, Europe, Asia, etc.)
- City/location selection within regions
- Full timezone validation
- Works with or without internet

## Files Added/Modified

### New Files
- `install/config/timezone-detection.sh` - Core detection logic
- `install/first-run/timezone.sh` - First-run timezone prompt
- `bin/omarchy-cmd-tzupdate-enhanced` - Enhanced timezone update command
- `bin/omarchy-cmd-tzupdate-manual` - Manual timezone selection interface

### Modified Files
- `install/config/timezones.sh` - Now runs detection during installation
- `bin/omarchy-cmd-first-run` - Includes timezone setup in first-run sequence
- `config/waybar/config.jsonc` - Enhanced clock interaction
- `bin/omarchy-menu` - Added timezone submenu options

## Error Handling

The enhanced system includes comprehensive error handling:
- **No Internet**: Gracefully falls back to manual selection
- **Invalid Timezones**: Validates timezone names before setting
- **Detection Failures**: Provides clear feedback and alternatives
- **Missing Dependencies**: Checks for required tools and provides fallbacks

## Benefits

1. **Improved User Experience**: Users get correct time immediately after installation
2. **Multiple Options**: Auto-detection, manual selection, and hybrid approaches
3. **Non-blocking**: Installation continues even if timezone detection fails
4. **Post-install Flexibility**: Easy timezone updates after installation
5. **Smart Defaults**: Sensible fallbacks ensure system always has a valid timezone

## Backward Compatibility

All existing timezone functionality remains intact:
- Original `omarchy-cmd-tzupdate` still works
- Existing waybar right-click behavior preserved
- All sudoers rules maintained for passwordless timezone updates

The enhancements are additive and don't break any existing workflows.