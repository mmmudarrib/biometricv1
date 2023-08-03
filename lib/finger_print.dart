import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zk_finger/finger_status.dart';
import 'package:zk_finger/finger_status_type.dart';
import 'package:zk_finger/zk_finger.dart';

class FingerPrint extends StatefulWidget {
  const FingerPrint({super.key});

  @override
  State<FingerPrint> createState() => _FingerPrintState();
}

class _FingerPrintState extends State<FingerPrint> {
  String? _platformVersion = 'Unknown';

  final TextEditingController _registerationCodeController =
      TextEditingController(text: "DEVD6586");
  final TextEditingController _biometricController = TextEditingController();

  String? score;
  String? verifiedId;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String? platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await ZkFinger.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }
    ZkFinger.imageStream.receiveBroadcastStream().listen(mapFingerImage);
    ZkFinger.statusChangeStream.receiveBroadcastStream().listen(updateStatus);

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Uint8List? fingerImages;
  String statusText = '';
  String stringLengthBytes = '';

  FingerStatus? fingerStatus;
  FingerStatusType? tempStatusType;

  void updateStatus(dynamic value) {
    Map<dynamic, dynamic> statusMap = value as Map<dynamic, dynamic>;
    FingerStatusType statusType =
        FingerStatusType.values[statusMap['fingerStatus']];
    fingerStatus = FingerStatus(
        statusMap['message'], statusType, statusMap['id'], statusMap['data']);

    print(fingerStatus);
    print(tempStatusType);

    if (statusType == tempStatusType &&
        tempStatusType == FingerStatusType.CAPTURE_ERROR) {
      //ignore capture error when finger device get stucked
    } else {
      tempStatusType = statusType;
      setState(() {
        setBiometricBase64TextField();
        statusText =
            '${"$statusText${fingerStatus!.statusType} Id: ${fingerStatus!.id}"}\n';
      });
    }
  }

  void setBiometricBase64TextField() {
    if (fingerStatus!.statusType == FingerStatusType.ENROLL_SUCCESS) {
      resetFieldsData();
      _biometricController.text = fingerStatus!.data;
      verifiedId = '${fingerStatus!.id} enroll';
    } else if (fingerStatus!.statusType ==
        FingerStatusType.ENROLL_ALREADY_EXIST) {
      resetFieldsData();
      score = fingerStatus!.data;
      verifiedId = '${fingerStatus!.id} already enrolled';
    } else if (fingerStatus!.statusType == FingerStatusType.VERIFIED_SUCCESS) {
      resetFieldsData();
      verifiedId = '${fingerStatus!.id} verified';
      score = fingerStatus!.data;
    } else if (fingerStatus!.statusType == FingerStatusType.FINGER_REGISTERED) {
      resetFieldsData();
      verifiedId = '${fingerStatus!.id} register';
      _biometricController.text = fingerStatus!.data;
    } else if (fingerStatus!.statusType == FingerStatusType.ENROLL_CONFIRM) {
      resetFieldsData();
      verifiedId = '${fingerStatus!.id} confirm';
      _biometricController.text = 'Current Confirm Index ${fingerStatus!.data}';
    }
    stringLengthBytes = 'Text Size: ${_biometricController.text.length} bytes';
    statusText = '$statusText$stringLengthBytes\n';
  }

  void resetFieldsData() {
    _biometricController.text = '';
    verifiedId = '';
    score = '';
  }

  void mapFingerImage(dynamic imageBytes) {
    setState(() {
      fingerImages = imageBytes;
    });
  }

  bool? isDeviceSupported;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Row(
            children: <Widget>[
              Column(
                children: <Widget>[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      elevation: 5,
                      padding: const EdgeInsets.all(12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    onPressed: () async {
                      bool? isSupported = await ZkFinger.isDeviceSupported();
                      setState(() {
                        isDeviceSupported = isSupported;
                        statusText =
                            "${statusText}Is zkteco Finger Print Supported: $isDeviceSupported";
                      });
                    },
                    child: const Text(
                      'Is Device Supported',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      elevation: 5,
                      padding: const EdgeInsets.all(12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    onPressed: () async {
                      await ZkFinger.openConnection(isLogEnabled: false);
                    },
                    child: const Text(
                      'Open Connection',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      elevation: 5,
                      padding: const EdgeInsets.all(12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    onPressed: () async {
                      await ZkFinger.startListen(
                          userId: _registerationCodeController.text);
                    },
                    child: const Text(
                      'Start Listening',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      elevation: 5,
                      padding: const EdgeInsets.all(12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    onPressed: () async {
                      await ZkFinger.enroll(
                          userId: _registerationCodeController.text);
                    },
                    child: const Text(
                      'Enroll Finger',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      elevation: 5,
                      padding: const EdgeInsets.all(12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    onPressed: () async {
                      await ZkFinger.verify(
                          userId: _registerationCodeController.text);
                    },
                    child: const Text(
                      'Verify Finger',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      elevation: 5,
                      padding: const EdgeInsets.all(12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    onPressed: () async {
                      await ZkFinger.clearFingerDatabase();
                    },
                    child: const Text(
                      'Clear finger\nDatabase',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      elevation: 5,
                      padding: const EdgeInsets.all(12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    onPressed: () async {
                      await ZkFinger.stopListen();
                    },
                    child: const Text(
                      'Stop Listening',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      elevation: 5,
                      padding: const EdgeInsets.all(12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    onPressed: () async {
                      await ZkFinger.closeConnection();
                    },
                    child: const Text(
                      'Close Connection',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  _getFingerStatusImage()
                ],
              ),
              fingerImages != null
                  ? Image.memory(
                      fingerImages!,
                      width: MediaQuery.of(context).size.width * .2,
                      height: double.infinity,
                      fit: BoxFit.contain,
                    )
                  : Text('Running on: $_platformVersion\n'),
              SizedBox(
                width: MediaQuery.of(context).size.width * .3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TextFormField(
                      controller: _registerationCodeController,
                      decoration: const InputDecoration(
                          labelText: "Registeration Code"),
                    ),
                    const Text('Biometric Base64 Text:',
                        style: TextStyle(fontSize: 14, color: Colors.blue)),
                    TextFormField(
                        controller: _biometricController,
                        maxLines: null,
                        style: const TextStyle(fontSize: 7)),
                    Text('Score: $score',
                        style:
                            const TextStyle(fontSize: 14, color: Colors.blue)),
                    Text('Verified Id: $verifiedId',
                        style:
                            const TextStyle(fontSize: 14, color: Colors.blue)),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        elevation: 5,
                        padding: const EdgeInsets.all(12.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                      onPressed: () async {
                        await ZkFinger.registerFinger(
                            userId: _registerationCodeController.text,
                            dataBase64: _biometricController.text);
                      },
                      child: const Text(
                        'Register User Biometric Base64 Data',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                  width: MediaQuery.of(context).size.width * .3,
                  child: Text('statusText: $statusText'))
            ],
          ),
        ),
      ),
    );
  }

  Widget _getFingerStatusImage() {
    if (fingerStatus == null) {
      return const SizedBox.shrink();
    }
    Color svgColor = Colors.black12;
    switch (fingerStatus!.statusType) {
      case FingerStatusType.STARTED_ALREADY:
      case FingerStatusType.STARTED_SUCCESS:
        svgColor = Colors.blue;
        break;
      case FingerStatusType.VERIFIED_START_FIRST:
      case FingerStatusType.VERIFIED_SUCCESS:
        svgColor = Colors.pink;
        break;
      case FingerStatusType.ENROLL_ALREADY_EXIST:
      case FingerStatusType.ENROLL_CONFIRM:
      case FingerStatusType.ENROLL_STARTED:
      case FingerStatusType.ENROLL_SUCCESS:
        svgColor = Colors.deepOrange;
        break;
      case FingerStatusType.STOPPED_ALREADY:
      case FingerStatusType.STOPPED_SUCCESS:
        svgColor = Colors.cyan;
        break;
      case FingerStatusType.FINGER_REGISTERED:
        svgColor = Colors.green;
        break;
      case FingerStatusType.FINGER_CLEARED:
        svgColor = Colors.yellow;
        break;
      case FingerStatusType.STARTED_FAILED:
      case FingerStatusType.STARTED_ERROR:
      case FingerStatusType.VERIFIED_FAILED:
      case FingerStatusType.ENROLL_FAILED:
      case FingerStatusType.STOPPED_ERROR:
      case FingerStatusType.CAPTURE_ERROR:
        svgColor = Colors.redAccent;
        break;
      default:
        svgColor = Colors.black38;
    }

    return const SizedBox.shrink();
  }
}
