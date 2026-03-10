# Flutter Auto Sync

A Flutter package that automatically stores API requests offline and syncs them when internet connectivity returns.

## Features

✔ Offline data storage  
✔ Automatic background sync  
✔ Retry mechanism  
✔ Queue-based request system  

## Installation

dependencies:
  flutter_auto_sync: ^0.0.2

## Usage

import 'package:flutter_auto_sync/flutter_auto_sync.dart';

await AutoSyncManager.init();

await AutoSyncManager.addToQueue(
  endpoint: "https://api.example.com/data",
  data: {"name": "Roopa"},
);

## Example
See the example folder for a full demo.