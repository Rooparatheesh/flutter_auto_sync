# Flutter Auto Sync

A Flutter package for offline data storage and automatic synchronization when internet connectivity returns.

## Features

- Offline data storage
- Automatic sync when internet returns
- Queue based API sync
- Connectivity detection

## Installation

Add this to pubspec.yaml

dependencies:
  flutter_auto_sync: ^0.0.1

## Usage

import 'package:flutter_auto_sync/flutter_auto_sync.dart';

await AutoSyncManager.init();

await AutoSyncManager.addToQueue(
  endpoint: "https://api.example.com/data",
  data: {"name": "Roopa"},
);