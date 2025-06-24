import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const moneytransferScreen());
}

class moneytransferScreen extends StatelessWidget {
  const moneytransferScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      body: const CashAdvanceApp(), // หรือเนื้อหาของหน้า Equipment
    );
  }
}

class CashAdvanceRequest {
  final String name;
  final String phone;
  final String amount;
  final DateTime date;

  CashAdvanceRequest({
    required this.name,
    required this.phone,
    required this.amount,
    required this.date,
  });
}

class CashAdvanceApp extends StatefulWidget {
  const CashAdvanceApp({Key? key}) : super(key: key);

  @override
  State<CashAdvanceApp> createState() => _CashAdvanceAppState();
}

class _CashAdvanceAppState extends State<CashAdvanceApp> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _amountController;
  late TextEditingController _dateController;
  late DateTime _selectedDate;

  // ตัวแปรสำหรับเก็บข้อความแจ้งเตือน
  String? _nameError;
  String? _phoneError;
  String? _amountError;
  String? _dateError;

  List<CashAdvanceRequest> requests = [];
  int? selectedRequestIndex;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _amountController = TextEditingController();
    _dateController = TextEditingController();
    _selectedDate = DateTime.now();
    _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _addNewRequest() {
    selectedRequestIndex = null;
    _clearForm();
    _resetErrors();
    _showFormDialog();
  }

  void _editRequest(int index) {
    selectedRequestIndex = index;
    final request = requests[index];
    _nameController.text = request.name;
    _phoneController.text = request.phone;
    _amountController.text = request.amount;
    _selectedDate = request.date;
    _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
    _resetErrors();
    _showFormDialog();
  }

  void _showFormDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            'เบิกล่วงหน้า',
                            style: TextStyle(
                              color: Color(0xFF25634B),
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'ชื่อ-นามสกุล',
                          style: TextStyle(
                            color: Color(0xFF30C39E),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'ระบุชื่อ-นามสกุล',
                            hintStyle: TextStyle(
                                color: Colors
                                    .grey), // เปลี่ยนสีของ hint text เป็นสีเทา
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 15, vertical: 10),
                            errorText: _nameError,
                          ),
                          onChanged: (value) {
                            setDialogState(() {
                              if (_nameError != null) _nameError = null;
                            });
                          },
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          'เบอร์โทรศัพท์',
                          style: TextStyle(
                            color: Color(0xFF30C39E),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          decoration: InputDecoration(
                            hintText: 'ระบุเบอร์โทรศัพท์',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 15, vertical: 10),
                            errorText: _phoneError,
                            counterText: "",
                          ),
                          onChanged: (value) {
                            setDialogState(() {
                              if (_phoneError != null) _phoneError = null;
                            });
                          },
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          'จำนวนเงินที่ต้องการเบิก',
                          style: TextStyle(
                            color: Color(0xFF30C39E),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'ระบุจำนวนเงิน',
                            suffixText: 'บาท',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 15, vertical: 10),
                            errorText: _amountError,
                          ),
                          onChanged: (value) {
                            setDialogState(() {
                              if (_amountError != null) _amountError = null;
                            });
                          },
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          'วันที่',
                          style: TextStyle(
                            color: Color(0xFF30C39E),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        TextField(
                          controller: _dateController,
                          readOnly: true,
                          decoration: InputDecoration(
                            hintText: 'เลือกวันที่',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 15, vertical: 10),
                            suffixIcon: Icon(Icons.calendar_today, size: 20),
                            errorText: _dateError,
                          ),
                          onTap: () async {
                            await _selectDateInDialog(context, setDialogState);
                            setDialogState(() {});
                          },
                        ),
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  side: const BorderSide(
                                      color: Color(0xFF30C39E)),
                                ),
                                child: const Text(
                                  'กลับ',
                                  style: TextStyle(
                                    color: Color(0xFF30C39E),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 60),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_validateInputsInDialog(setDialogState)) {
                                    _saveRequestFromDialog();
                                    Navigator.of(context).pop();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF30C39E),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text(
                                  'บันทึก',
                                  style: TextStyle(
                                    color: Color(0xFFFFFFFF),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _selectDateInDialog(
      BuildContext context, StateSetter setDialogState) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF30C39E),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF30C39E),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setDialogState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
        _dateError = null;
      });
    }
  }

  bool _validateInputsInDialog(StateSetter setDialogState) {
    bool isValid = true;

    setDialogState(() {
      _resetErrors();

      if (_nameController.text.isEmpty) {
        _nameError = "กรุณาระบุชื่อ-นามสกุล";
        isValid = false;
      }

      if (_phoneController.text.isEmpty) {
        _phoneError = "กรุณาระบุเบอร์โทรศัพท์";
        isValid = false;
      }

      if (_amountController.text.isEmpty) {
        _amountError = "กรุณาระบุจำนวนเงิน";
        isValid = false;
      }

      if (_dateController.text.isEmpty) {
        _dateError = "กรุณาเลือกวันที่";
        isValid = false;
      }
    });

    return isValid;
  }

  void _saveRequestFromDialog() {
    setState(() {
      if (selectedRequestIndex != null) {
        requests[selectedRequestIndex!] = CashAdvanceRequest(
          name: _nameController.text,
          phone: _phoneController.text,
          amount: _amountController.text,
          date: _selectedDate,
        );
      } else {
        requests.add(CashAdvanceRequest(
          name: _nameController.text,
          phone: _phoneController.text,
          amount: _amountController.text,
          date: _selectedDate,
        ));
      }
      selectedRequestIndex = null;
    });
  }

  void _resetErrors() {
    _nameError = null;
    _phoneError = null;
    _amountError = null;
    _dateError = null;
  }

  void _showRequestDetails(int index) {
    setState(() {
      selectedRequestIndex = index;
    });
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('ยืนยันการลบ'),
          content: const Text('คุณต้องการลบรายการนี้ใช่หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteRequest();
              },
              child: const Text('ลบ', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _deleteRequest() {
    if (selectedRequestIndex != null) {
      setState(() {
        requests.removeAt(selectedRequestIndex!);
        selectedRequestIndex = null;
      });
    }
  }

  void _clearForm() {
    _nameController.clear();
    _phoneController.clear();
    _amountController.clear();
    _selectedDate = DateTime.now();
    _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
  }

  void _goBack() {
    setState(() {
      selectedRequestIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เบิกล่วงหน้า',
            style: TextStyle(
              fontSize: 20,
              color: Color(0xFF25634B),
              fontWeight: FontWeight.w800,
            )),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: _buildCurrentScreen(),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildCurrentScreen() {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    if (selectedRequestIndex != null) {
      return _buildRequestDetails();
    } else {
      return _buildBody(width, height);
    }
  }

  Widget _buildBody(double width, double height) {
    if (requests.isEmpty) {
      return _buildEmptyState(width, height);
    } else {
      return _buildRequestList(width, height);
    }
  }

  Widget _buildEmptyState(double width, double height) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: Center(
        child: GestureDetector(
          onTap: _addNewRequest,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: width * 0.2,
                height: height * 0.1,
                decoration: ShapeDecoration(
                  color: const Color(0xFF34D396),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(38),
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'กดเพื่อเบิกล่วงหน้า',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF25634B),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestList(double width, double height) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: height * 0.1, // ปรับให้มีพื้นที่ด้านล่างสำหรับปุ่ม
            child: ListView.builder(
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                return _buildRequestCard(request, index, width, height);
              },
            ),
          ),
          Positioned(
            bottom: -8, // กำหนดให้ปุ่มอยู่ที่ด้านล่าง
            left: 60,
            right: 60,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: SizedBox(
                width: double.infinity, // ทำให้ปุ่มมีความกว้างเต็มที่
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: _addNewRequest,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'เพิ่มการขอเบิก',
                    style: TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF34D396),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(
      CashAdvanceRequest request, int index, double width, double height) {
    final formattedDate = DateFormat('dd/MM/yyyy').format(request.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        child: InkWell(
          onTap: () => _showRequestDetails(index),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ชื่อ ${request.name} tel. ${request.phone}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF25634B),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${request.amount} บาท",
                      style: const TextStyle(
                        color: Color(0xFF25634B),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestDetails() {
    if (selectedRequestIndex == null) return Container();

    final request = requests[selectedRequestIndex!];
    final formattedDate = DateFormat('dd/MM/yyyy').format(request.date);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          color: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'เบิกล่วงหน้า',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF25634B),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'ชื่อ ${request.name} tel.${request.phone}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF25634B),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'จำนวนเงินที่ต้องการเบิก',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF25634B),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "${request.amount} บาท",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF25634B),
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'วันที่',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF25634B),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF25634B),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _editRequest(selectedRequestIndex!);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        minimumSize: const Size(100, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text('แก้ไข',
                          style: TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          )),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                        onPressed: _showDeleteConfirmation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          minimumSize: const Size(100, 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text('ลบ',
                            style: TextStyle(
                              color: Color(0xFFFFFFFF),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ))),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _goBack,
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          side: const BorderSide(color: Color(0xFF34D396)),
                        ),
                        child: const Text('กลับ',
                            style: TextStyle(
                              color: Color(0xFF34D396),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            )),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _goBack();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF34D396),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text('ยืนยัน',
                            style: TextStyle(
                              color: Color(0xFFFFFFFF),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            )),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = MediaQuery.of(context).size.width;
        final height = MediaQuery.of(context).size.height;

        return Container(
          height: 110,
          padding: const EdgeInsets.all(16.0),
          child: Stack(
            children: [
              // Custom bottom navigation bar container (white background)
              Positioned(
                bottom: 0,
                left: width * 0.03,
                right: width * 0.03,
                child: Container(
                  height: height * 0.07,
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(83.50),
                    ),
                    shadows: [
                      BoxShadow(
                        color: Color(0x7F646464),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                        spreadRadius: 0,
                      )
                    ],
                  ),
                ),
              ),
              // ปุ่มซ้าย
              Positioned(
                bottom: height * 0.01, // ✅ ควบคุม position เอง
                left: width * 0.07, // ✅ ควบคุม position เอง
                child: Container(
                  width: width * 0.12,
                  height: height * 0.05,
                  decoration: ShapeDecoration(
                    color: Color(0xFF34D396),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(38),
                    ),
                  ),
                ),
              ),
              // ปุ่มขวา
              Positioned(
                bottom: height * 0.01, // ✅ ควบคุม position เอง
                right: width * 0.07, // ✅ ควบคุม position เอง
                child: Container(
                  width: width * 0.12,
                  height: height * 0.05,
                  decoration: ShapeDecoration(
                    color: Color(0xFF34D396),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(38),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
