import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'dart:async';

final bleProvider = Provider((ref) => FlutterReactiveBle());

final bluetoothServiceProvider = StateNotifierProvider<BluetoothService, BluetoothState>((ref) {
  return BluetoothService(ref.watch(bleProvider));
});

class BluetoothState {
  final List<DiscoveredDevice> discoveredDevices;
  final DiscoveredDevice? connectedDevice;
  final bool isScanning;

  BluetoothState({
    this.discoveredDevices = const [],
    this.connectedDevice,
    this.isScanning = false,
  });

  BluetoothState copyWith({
    List<DiscoveredDevice>? discoveredDevices,
    DiscoveredDevice? connectedDevice,
    bool? isScanning,
  }) {
    return BluetoothState(
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      connectedDevice: connectedDevice ?? this.connectedDevice,
      isScanning: isScanning ?? this.isScanning,
    );
  }
}

// Manages Bluetooth Low Energy (BLE) scanning and connections.
class BluetoothService extends StateNotifier<BluetoothState> {
  final FlutterReactiveBle _ble;
  StreamSubscription? _scanSubscription;
  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;

  BluetoothService(this._ble) : super(BluetoothState());

  // Starts scanning for nearby BLE devices.
  void startScan() {
    state = state.copyWith(isScanning: true, discoveredDevices: []);
    _scanSubscription?.cancel();
    _scanSubscription = _ble.scanForDevices(withServices: []).listen((device) {
      final knownDevices = state.discoveredDevices;
      final deviceIndex = knownDevices.indexWhere((d) => d.id == device.id);
      if (deviceIndex != -1) {
        final updatedDevices = List<DiscoveredDevice>.from(knownDevices);
        updatedDevices[deviceIndex] = device;
        state = state.copyWith(discoveredDevices: updatedDevices);
      } else {
        state = state.copyWith(discoveredDevices: [...knownDevices, device]);
      }
    });
  }

  // Stops the BLE scan.
  void stopScan() {
    _scanSubscription?.cancel();
    state = state.copyWith(isScanning: false);
  }

  // Connects to a specific BLE device.
  void connect(DiscoveredDevice device) {
    stopScan();
    _connectionSubscription?.cancel();
    _connectionSubscription = _ble.connectToDevice(id: device.id).listen((connectionState) {
      if (connectionState.connectionState == DeviceConnectionState.connected) {
        state = state.copyWith(connectedDevice: device);
      }
      if (connectionState.connectionState == DeviceConnectionState.disconnected) {
        state = state.copyWith(connectedDevice: null);
      }
    });
  }

  // Disconnects from the currently connected device.
  void disconnect() {
    _connectionSubscription?.cancel();
    state = state.copyWith(connectedDevice: null);
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    super.dispose();
  }
}
