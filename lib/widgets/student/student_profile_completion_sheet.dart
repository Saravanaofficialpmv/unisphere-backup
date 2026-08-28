import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:unisphere/core/constants/app_colors.dart';
import 'package:unisphere/models/student_profile_model.dart';
import 'package:unisphere/services/auth_service.dart';
import 'package:unisphere/services/firebase_firestore_service.dart';
import 'package:unisphere/services/storage_service.dart';

class StudentProfileCompletionSheet extends ConsumerStatefulWidget {
  const StudentProfileCompletionSheet({super.key});

  @override
  ConsumerState<StudentProfileCompletionSheet> createState() =>
      _StudentProfileCompletionSheetState();
}

class _StudentProfileCompletionSheetState
    extends ConsumerState<StudentProfileCompletionSheet> {
  int _currentStep = 1;
  bool _isSavingDraft = false;
  bool _isSubmitting = false;

  // Education Toggles
  bool _has12th = true;
  bool _hasDiploma = false;

  // Validation Error State Flags
  bool _dobError = false;
  bool _genderError = false;
  bool _bloodGroupError = false;
  bool _religionError = false;
  bool _communityError = false;
  bool _primaryMobileError = false;
  bool _fatherNameError = false;
  bool _motherNameError = false;

  // ── Step 1: Personal ──
  final _nameController = TextEditingController();
  final _regNoController = TextEditingController();
  final _deptController = TextEditingController();
  final _emailController = TextEditingController();
  String? _dob;
  String? _gender;
  String? _bloodGroup;
  final String _nationality = 'Indian';
  String? _religion;
  String? _community;
  final _casteController = TextEditingController();
  String? _motherTongue;
  bool _isFirstGraduate = false;
  bool _isDifferentlyAbled = false;
  final _disabilityController = TextEditingController();
  String? _studentPhotoUrl;
  bool _isUploadingPhoto = false;

  // ── Step 2: Contact & Address ──
  final _primaryMobileController = TextEditingController();
  final _alternateMobileController = TextEditingController();
  final _personalEmailController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  String? _emergencyRelation;
  final _emergencyPhoneController = TextEditingController();

  // Permanent Address
  final _permLine1Controller = TextEditingController();
  final _permLine2Controller = TextEditingController();
  final _permAreaController = TextEditingController();
  final _permCityController = TextEditingController();
  final _permDistrictController = TextEditingController();
  final _permStateController = TextEditingController(text: 'Tamil Nadu');
  final _permPincodeController = TextEditingController();

  // Current Address
  bool _sameAsPermanent = true;
  final _currLine1Controller = TextEditingController();
  final _currLine2Controller = TextEditingController();
  final _currAreaController = TextEditingController();
  final _currCityController = TextEditingController();
  final _currDistrictController = TextEditingController();
  final _currStateController = TextEditingController(text: 'Tamil Nadu');
  final _currPincodeController = TextEditingController();

  // ── Step 3: Parents & Guardian ──
  // Father
  String? _fatherPhotoUrl;
  final _fatherNameController = TextEditingController();
  final _fatherPhoneController = TextEditingController();
  final _fatherEmailController = TextEditingController(); // OPTIONAL
  String? _fatherQual;
  final _fatherOccupationController = TextEditingController();
  String? _fatherIncome;

  // Mother
  String? _motherPhotoUrl;
  final _motherNameController = TextEditingController();
  final _motherPhoneController = TextEditingController();
  final _motherEmailController = TextEditingController(); // OPTIONAL
  String? _motherQual;
  final _motherOccupationController = TextEditingController();
  String? _motherIncome;

  // Parent Annual Income (Combined)
  String? _parentAnnualIncome;

  // Guardian (Optional)
  bool _hasGuardian = false;
  String? _guardianPhotoUrl;
  final _guardianNameController = TextEditingController();
  String? _guardianRelation;
  final _guardianPhoneController = TextEditingController();
  final _guardianEmailController = TextEditingController();
  final _guardianQualController = TextEditingController();
  final _guardianOccupationController = TextEditingController();
  final _guardianAddressController = TextEditingController();

  // ── Step 4: Previous Education ──
  // 10th
  // 10th
  final _tenthSchoolController = TextEditingController();
  final _tenthAddressController = TextEditingController();
  String? _tenthBoard;
  String _tenthMedium = 'English';
  final _tenthOtherMediumController = TextEditingController();
  final _tenthRegNoController = TextEditingController();
  final _tenthYearController = TextEditingController();
  final _tenthTotalController = TextEditingController(text: '500');
  final _tenthObtainedController = TextEditingController();
  double _tenthPercentage = 0.0;

  String get _effectiveTenthMedium => _tenthMedium == 'Other'
      ? (_tenthOtherMediumController.text.trim().isNotEmpty ? _tenthOtherMediumController.text.trim() : 'Other')
      : _tenthMedium;

  // 12th / Diploma
  final _twelfthSchoolController = TextEditingController();
  final _twelfthAddressController = TextEditingController();
  String? _twelfthBoard;
  String _twelfthMedium = 'English';
  final _twelfthOtherMediumController = TextEditingController();
  final _twelfthRegNoController = TextEditingController();
  final _twelfthYearController = TextEditingController();
  final _twelfthTotalController = TextEditingController(text: '600');
  final _twelfthObtainedController = TextEditingController();
  double _twelfthPercentage = 0.0;

  String get _effectiveTwelfthMedium => _twelfthMedium == 'Other'
      ? (_twelfthOtherMediumController.text.trim().isNotEmpty ? _twelfthOtherMediumController.text.trim() : 'Other')
      : _twelfthMedium;

  // Diploma / Polytechnic
  String _diplomaEvalMode = 'Percentage'; // 'Percentage' or 'Grade'
  String _selectedDiplomaGrade = 'A+';
  String _diplomaMedium = 'English';
  final _diplomaOtherMediumController = TextEditingController();
  final _diplomaCollegeController = TextEditingController();
  final _diplomaAddressController = TextEditingController();
  final _diplomaBranchController = TextEditingController();
  final _diplomaYearController = TextEditingController();
  final _diplomaTotalController = TextEditingController(text: '100');
  final _diplomaObtainedController = TextEditingController();
  double _diplomaPercentage = 0.0;

  String get _effectiveDiplomaMedium => _diplomaMedium == 'Other'
      ? (_diplomaOtherMediumController.text.trim().isNotEmpty ? _diplomaOtherMediumController.text.trim() : 'Other')
      : _diplomaMedium;

  // ── Step 5: Living & Accommodation ──
  LivingType? _selectedLivingType;
  final _hostelNameController = TextEditingController();
  final _hostelBlockController = TextEditingController();
  final _hostelRoomController = TextEditingController();
  final _pgNameController = TextEditingController();
  final _pgAddressController = TextEditingController();
  final _rentedAddressController = TextEditingController();
  final _roommatesController = TextEditingController();
  final _accOwnerNameController = TextEditingController();
  final _accOwnerPhoneController = TextEditingController();
  final _accAddressController = TextEditingController();

  bool get _isDayScholar => _selectedLivingType != LivingType.collegeHostel;

  // ── Step 6: Day Scholar Transport (STRICTLY ONLY: BUS, BIKE, WALK) ──
  PrimaryTransportMode? _transportMode;
  String? _busType;
  final _boardingPointController = TextEditingController();
  final _busStopController = TextEditingController();
  final _pickupTimeController = TextEditingController();
  String? _vehicleType;
  final _vehicleRegNoController = TextEditingController();
  final String _driverType = 'Student';
  bool _parkingPermission = true;
  final bool _licenceAvailable = true;
  final _distanceController = TextEditingController(text: '12 km');
  final _travelTimeController = TextEditingController(text: '30 mins');
  final _arrivalTimeController = TextEditingController(text: '08:25 AM');
  final _departureTimeController = TextEditingController(text: '05:00 PM');

  // ── Step 7: Documents ──
  final List<StudentDocument> _uploadedDocuments = [];

  List<StudentDocument> get _activeDocuments {
    final defaultList = [
      StudentDocument(id: 'doc_photo', name: 'Student Passport Photo', isRequired: true, fileUrl: '', fileName: ''),
      StudentDocument(id: 'doc_10th', name: '10th Standard Marksheet', isRequired: true, fileUrl: '', fileName: ''),
      if (_has12th)
        StudentDocument(id: 'doc_12th', name: '12th Standard Marksheet', isRequired: true, fileUrl: '', fileName: ''),
      if (_hasDiploma)
        StudentDocument(id: 'doc_diploma', name: 'Polytechnic / Diploma Marksheet', isRequired: true, fileUrl: '', fileName: ''),
      StudentDocument(id: 'doc_tc', name: 'Transfer Certificate (TC)', isRequired: true, fileUrl: '', fileName: ''),
      StudentDocument(id: 'doc_community', name: 'Community Certificate', isRequired: false, fileUrl: '', fileName: ''),
    ];

    return defaultList.map((item) {
      final existingIdx = _uploadedDocuments.indexWhere((d) => d.id == item.id);
      return existingIdx != -1 ? _uploadedDocuments[existingIdx] : item;
    }).toList();
  }

  // ── Step 8: Confirmation ──
  bool _isConfirmed = false;

  @override
  void initState() {
    super.initState();
    _loadInitialUserData();
  }

  void _loadInitialUserData() async {
    final user = ref.read(currentUserProvider).value ?? ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    final meta = user.metadata ?? {};
    _nameController.text = meta['fullName'] ?? user.name;
    _regNoController.text = meta['registerNumber'] ?? '';
    _deptController.text = meta['department'] ?? 'Computer Science';
    _emailController.text = user.email;
    _studentPhotoUrl = user.profileImageUrl ?? meta['passportPhotoUrl'] ?? meta['photoUrl'];
    final parentsMeta = meta['parents'] as Map<String, dynamic>? ?? {};
    if (parentsMeta['parentAnnualIncome'] != null || parentsMeta['annualIncome'] != null) {
      _parentAnnualIncome = parentsMeta['parentAnnualIncome'] ?? parentsMeta['annualIncome'];
    }

    // Load draft if available
    final draft = await ref.read(firebaseFirestoreServiceProvider).getStudentProfileDraft(user.uid);
    if (draft != null && mounted) {
      setState(() {
        if (draft['dob'] != null) _dob = draft['dob'];
        if (draft['primaryMobile'] != null) _primaryMobileController.text = draft['primaryMobile'];
        if (draft['permLine1'] != null) _permLine1Controller.text = draft['permLine1'];
        if (draft['permCity'] != null) _permCityController.text = draft['permCity'];
        if (draft['permState'] != null) _permStateController.text = draft['permState'];
        if (draft['permPincode'] != null) _permPincodeController.text = draft['permPincode'];
        if (draft['currLine1'] != null) _currLine1Controller.text = draft['currLine1'];
        if (draft['currCity'] != null) _currCityController.text = draft['currCity'];
        if (draft['currState'] != null) _currStateController.text = draft['currState'];
        if (draft['currPincode'] != null) _currPincodeController.text = draft['currPincode'];
        if (draft['fatherName'] != null) _fatherNameController.text = draft['fatherName'];
        if (draft['fatherPhone'] != null) _fatherPhoneController.text = draft['fatherPhone'];
        if (draft['motherName'] != null) _motherNameController.text = draft['motherName'];
        if (draft['motherPhone'] != null) _motherPhoneController.text = draft['motherPhone'];
        if (draft['tenthObtained'] != null) _tenthObtainedController.text = draft['tenthObtained'];
        if (draft['twelfthObtained'] != null) _twelfthObtainedController.text = draft['twelfthObtained'];
        if (draft['tenthAddress'] != null) _tenthAddressController.text = draft['tenthAddress'];
        if (draft['twelfthAddress'] != null) _twelfthAddressController.text = draft['twelfthAddress'];
        if (draft['diplomaAddress'] != null) _diplomaAddressController.text = draft['diplomaAddress'];
        if (draft['tenthMedium'] != null) _tenthMedium = draft['tenthMedium'];
        if (draft['twelfthMedium'] != null) _twelfthMedium = draft['twelfthMedium'];
        if (draft['diplomaMedium'] != null) _diplomaMedium = draft['diplomaMedium'];
        if (draft['tenthOtherMedium'] != null) _tenthOtherMediumController.text = draft['tenthOtherMedium'];
        if (draft['twelfthOtherMedium'] != null) _twelfthOtherMediumController.text = draft['twelfthOtherMedium'];
        if (draft['diplomaOtherMedium'] != null) _diplomaOtherMediumController.text = draft['diplomaOtherMedium'];
        if (draft['has12th'] != null) _has12th = draft['has12th'];
        if (draft['hasDiploma'] != null) _hasDiploma = draft['hasDiploma'];
        if (draft['diplomaEvalMode'] != null) _diplomaEvalMode = draft['diplomaEvalMode'];
        if (draft['selectedDiplomaGrade'] != null) _selectedDiplomaGrade = draft['selectedDiplomaGrade'];
        if (draft['diplomaCollege'] != null) _diplomaCollegeController.text = draft['diplomaCollege'];
        if (draft['diplomaBranch'] != null) _diplomaBranchController.text = draft['diplomaBranch'];
        if (draft['diplomaObtained'] != null) _diplomaObtainedController.text = draft['diplomaObtained'];
        if (draft['diplomaTotal'] != null) _diplomaTotalController.text = draft['diplomaTotal'];
        if (draft['diplomaYear'] != null) _diplomaYearController.text = draft['diplomaYear'];
        if (draft['pgName'] != null) _pgNameController.text = draft['pgName'];
        if (draft['pgAddress'] != null) _pgAddressController.text = draft['pgAddress'];
        if (draft['rentedAddress'] != null) _rentedAddressController.text = draft['rentedAddress'];
        if (draft['roommateRegisterNumbers'] != null || draft['roommates'] != null) {
          _roommatesController.text = draft['roommateRegisterNumbers'] ?? draft['roommates'];
        }
        if (draft['documents'] != null && draft['documents'] is List) {
          _uploadedDocuments.clear();
          for (var d in (draft['documents'] as List)) {
            if (d is Map<String, dynamic>) {
              _uploadedDocuments.add(StudentDocument.fromMap(d));
            }
          }
        }
        _calculateEducationPercentages();
      });
    }
  }

  void _calculateEducationPercentages() {
    final tTotal = double.tryParse(_tenthTotalController.text) ?? 500;
    final tObtained = double.tryParse(_tenthObtainedController.text) ?? 0;
    if (tTotal > 0) _tenthPercentage = (tObtained / tTotal) * 100;

    final twTotal = double.tryParse(_twelfthTotalController.text) ?? 600;
    final twObtained = double.tryParse(_twelfthObtainedController.text) ?? 0;
    if (twTotal > 0) _twelfthPercentage = (twObtained / twTotal) * 100;

    if (_diplomaEvalMode == 'Grade') {
      final grade = _diplomaObtainedController.text.trim().toUpperCase();
      switch (grade) {
        case 'O':
          _diplomaPercentage = 95.0;
          break;
        case 'A+':
          _diplomaPercentage = 85.0;
          break;
        case 'A':
          _diplomaPercentage = 75.0;
          break;
        case 'B+':
          _diplomaPercentage = 65.0;
          break;
        case 'B':
          _diplomaPercentage = 55.0;
          break;
        case 'C':
          _diplomaPercentage = 45.0;
          break;
        default:
          _diplomaPercentage = 80.0;
      }
    } else {
      final dTotal = double.tryParse(_diplomaTotalController.text) ?? 100;
      final dObtained = double.tryParse(_diplomaObtainedController.text) ?? 0;
      if (dTotal > 0) _diplomaPercentage = (dObtained / dTotal) * 100;
    }
  }

  Future<void> _saveDraft() async {
    final user = ref.read(currentUserProvider).value ?? ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    setState(() => _isSavingDraft = true);
    await ref.read(firebaseFirestoreServiceProvider).saveStudentProfileDraft(user.uid, {
      'dob': _dob,
      'primaryMobile': _primaryMobileController.text,
      'permLine1': _permLine1Controller.text,
      'permCity': _permCityController.text,
      'permState': _permStateController.text,
      'permPincode': _permPincodeController.text,
      'currLine1': _currLine1Controller.text,
      'currCity': _currCityController.text,
      'currState': _currStateController.text,
      'currPincode': _currPincodeController.text,
      'fatherName': _fatherNameController.text,
      'fatherPhone': _fatherPhoneController.text,
      'motherName': _motherNameController.text,
      'motherPhone': _motherPhoneController.text,
      'tenthObtained': _tenthObtainedController.text,
      'twelfthObtained': _twelfthObtainedController.text,
      'tenthAddress': _tenthAddressController.text,
      'twelfthAddress': _twelfthAddressController.text,
      'diplomaAddress': _diplomaAddressController.text,
      'tenthMedium': _tenthMedium,
      'twelfthMedium': _twelfthMedium,
      'diplomaMedium': _diplomaMedium,
      'tenthOtherMedium': _tenthOtherMediumController.text,
      'twelfthOtherMedium': _twelfthOtherMediumController.text,
      'diplomaOtherMedium': _diplomaOtherMediumController.text,
      'has12th': _has12th,
      'hasDiploma': _hasDiploma,
      'diplomaEvalMode': _diplomaEvalMode,
      'selectedDiplomaGrade': _selectedDiplomaGrade,
      'diplomaCollege': _diplomaCollegeController.text,
      'diplomaBranch': _diplomaBranchController.text,
      'diplomaObtained': _diplomaObtainedController.text,
      'diplomaTotal': _diplomaTotalController.text,
      'diplomaYear': _diplomaYearController.text,
      'livingType': _selectedLivingType?.name ?? '',
      'pgName': _pgNameController.text,
      'pgAddress': _pgAddressController.text,
      'rentedAddress': _rentedAddressController.text,
      'roommateRegisterNumbers': _roommatesController.text,
      'roommates': _roommatesController.text,
      'transportMode': _transportMode?.name ?? '',
      'documents': _activeDocuments.map((d) => d.toMap()).toList(),
    });
    if (mounted) {
      setState(() => _isSavingDraft = false);
    }
  }

  int get _totalSteps => _isDayScholar ? 8 : 7;
  int get _displayStepNumber => (_currentStep == 6 && !_isDayScholar) ? 6 : _currentStep;

  void _fillMockData() {
    setState(() {
      // Step 1: Personal
      _dob = '15/05/2005';
      _gender = 'Male';
      _bloodGroup = 'O+';
      _religion = 'Hindu';
      _community = 'BC';
      _casteController.text = 'Kongu Vellalar';
      _motherTongue = 'Tamil';
      _isFirstGraduate = true;
      _isDifferentlyAbled = false;
      _dobError = false;
      _genderError = false;
      _bloodGroupError = false;
      _religionError = false;
      _communityError = false;

      // Step 2: Contact & Address
      _primaryMobileController.text = '+91 98765 43210';
      _alternateMobileController.text = '+91 98765 00000';
      _personalEmailController.text = 'student.test@gmail.com';
      _emergencyNameController.text = 'Senthil Kumar M';
      _emergencyRelation = 'Father';
      _emergencyPhoneController.text = '+91 99944 12345';
      _permLine1Controller.text = '123, Anna Nagar 2nd Street';
      _permCityController.text = 'Karur';
      _permPincodeController.text = '639002';
      _primaryMobileError = false;

      // Step 3: Parents & Guardian
      _fatherNameController.text = 'Senthil Kumar M';
      _fatherPhoneController.text = '+91 98765 11111';
      _fatherEmailController.text = 'senthilkumar@gmail.com';
      _fatherQual = 'Bachelor Degree';
      _fatherOccupationController.text = 'Business';
      _fatherIncome = '₹3,00,000 - ₹5,00,000';
      _motherNameController.text = 'Lakshmi S';
      _motherPhoneController.text = '+91 98765 22222';
      _motherQual = 'School';
      _motherOccupationController.text = 'Homemaker';
      _motherIncome = '₹1,00,000 - ₹3,00,000';
      _parentAnnualIncome = '₹4,00,000 - ₹8,00,000';
      _studentPhotoUrl = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300';
      _fatherNameError = false;
      _motherNameError = false;

      // Step 4: Previous Education
      _has12th = true;
      _hasDiploma = true;
      _tenthSchoolController.text = 'Government Higher Sec School';
      _tenthAddressController.text = 'Main Road, Karur, Tamil Nadu';
      _tenthBoard = 'State Board';
      _tenthMedium = 'English';
      _tenthRegNoController.text = '10TH98765';
      _tenthYearController.text = '2021';
      _tenthTotalController.text = '500';
      _tenthObtainedController.text = '465';
      _twelfthSchoolController.text = 'VSB Higher Sec School';
      _twelfthAddressController.text = 'Covai Road, Karur, Tamil Nadu';
      _twelfthBoard = 'State Board';
      _twelfthMedium = 'English';
      _twelfthRegNoController.text = '12TH12345';
      _twelfthYearController.text = '2023';
      _twelfthTotalController.text = '600';
      _twelfthObtainedController.text = '552';

      // Diploma
      _diplomaEvalMode = 'Grade';
      _selectedDiplomaGrade = 'A+';
      _diplomaCollegeController.text = 'VSB Polytechnic College';
      _diplomaAddressController.text = 'Covai Road, Karur, Tamil Nadu';
      _diplomaBranchController.text = 'Diploma in Computer Engineering';
      _diplomaYearController.text = '2025';
      _diplomaTotalController.text = 'First Class with Distinction';
      _diplomaObtainedController.text = 'A+';

      _calculateEducationPercentages();

      // Step 5 & 6: Living & Transport
      _selectedLivingType = LivingType.homeFamily;
      _pgNameController.text = 'Sri Sai Men\'s PG';
      _pgAddressController.text = 'Covai Road, Near VSB Campus, Karur';
      _rentedAddressController.text = '12/A, Gandhigramam 3rd Street, Karur';
      _roommatesController.text = '7378211CS101, 7378211CS105';
      _transportMode = PrimaryTransportMode.BUS;
      _busType = 'College Bus';
      _boardingPointController.text = 'Gandhigramam';
      _busStopController.text = 'College Main Gate';

      // Step 7: Documents Mock Setup
      _uploadedDocuments.clear();
      _uploadedDocuments.addAll([
        StudentDocument(id: 'doc_photo', name: 'Student Passport Photo', isRequired: true, fileName: 'passport_photo.jpg (0.8 MB)', fileUrl: 'https://unisphere.edu/docs/photo.jpg', status: 'uploaded'),
        StudentDocument(id: 'doc_10th', name: '10th Standard Marksheet', isRequired: true, fileName: '10th_marksheet.pdf (1.4 MB)', fileUrl: 'https://unisphere.edu/docs/10th.pdf', status: 'uploaded'),
        StudentDocument(id: 'doc_12th', name: '12th Standard Marksheet', isRequired: true, fileName: '12th_marksheet.pdf (1.6 MB)', fileUrl: 'https://unisphere.edu/docs/12th.pdf', status: 'uploaded'),
        StudentDocument(id: 'doc_diploma', name: 'Polytechnic / Diploma Certificate', isRequired: true, fileName: 'diploma_certificate.pdf (1.2 MB)', fileUrl: 'https://unisphere.edu/docs/diploma.pdf', status: 'uploaded'),
        StudentDocument(id: 'doc_tc', name: 'Transfer Certificate (TC)', isRequired: true, fileName: 'transfer_certificate.pdf (0.9 MB)', fileUrl: 'https://unisphere.edu/docs/tc.pdf', status: 'uploaded'),
        StudentDocument(id: 'doc_community', name: 'Community Certificate', isRequired: false, fileName: 'community_cert.pdf (0.7 MB)', fileUrl: 'https://unisphere.edu/docs/community.pdf', status: 'uploaded'),
      ]);

      // Step 8: Confirmation
      _isConfirmed = true;
    });
  }

  int get _progressPercentage {
    final stepProgress = (_currentStep / _totalSteps * 100).round();
    return stepProgress.clamp(10, 100);
  }

  void _nextStep() {
    if (_currentStep == 1) {
      final dobErr = _dob == null || _dob!.isEmpty;
      final genderErr = _gender == null;
      final bgErr = _bloodGroup == null;
      final relErr = _religion == null;
      final commErr = _community == null;

      if (dobErr || genderErr || bgErr || relErr || commErr) {
        setState(() {
          _dobError = dobErr;
          _genderError = genderErr;
          _bloodGroupError = bgErr;
          _religionError = relErr;
          _communityError = commErr;
        });
        return;
      }
    }
    if (_currentStep == 2 && _primaryMobileController.text.trim().isEmpty) {
      setState(() => _primaryMobileError = true);
      return;
    }
    if (_currentStep == 3) {
      final fEmpty = _fatherNameController.text.trim().isEmpty;
      final mEmpty = _motherNameController.text.trim().isEmpty;
      if (fEmpty || mEmpty) {
        setState(() {
          _fatherNameError = fEmpty;
          _motherNameError = mEmpty;
        });
        return;
      }
    }
    if (_currentStep == 4) {
      final tenthEmpty = _tenthSchoolController.text.trim().isEmpty || _tenthObtainedController.text.trim().isEmpty;
      final twelfthEmpty = _has12th && (_twelfthSchoolController.text.trim().isEmpty || _twelfthObtainedController.text.trim().isEmpty);
      final diplomaEmpty = _hasDiploma && (_diplomaCollegeController.text.trim().isEmpty || _diplomaObtainedController.text.trim().isEmpty);

      if (tenthEmpty || twelfthEmpty || diplomaEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Please fill all compulsory Previous Education details for your selected qualification pathway.'),
            backgroundColor: Color(0xFFEF4444),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
    }

    _saveDraft();

    setState(() {
      if (_currentStep < 8) {
        _currentStep++;
      }
    });
  }

  void _previousStep() {
    setState(() {
      if (_currentStep > 1) {
        _currentStep--;
      }
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  Future<void> _submitFinalProfile() async {
    if (!_isConfirmed) {
      _showError('Please confirm that the information provided is accurate.');
      return;
    }

    final user = ref.read(currentUserProvider).value ?? ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    _calculateEducationPercentages();

    final profile = FullStudentProfileModel(
      studentUid: user.uid,
      completionStatus: 'submitted',
      completionPercentage: 100,
      personal: StudentPersonalDetails(
        fullName: _nameController.text.trim(),
        registerNumber: _regNoController.text.trim(),
        department: _deptController.text.trim(),
        collegeEmail: _emailController.text.trim(),
        profilePhotoUrl: _studentPhotoUrl,
        dateOfBirth: _dob,
        gender: _gender ?? 'Male',
        bloodGroup: _bloodGroup ?? 'O+',
        nationality: _nationality,
        religion: _religion ?? 'Hindu',
        community: _community ?? 'BC',
        caste: _casteController.text.trim(),
        motherTongue: _motherTongue ?? 'Tamil',
        isFirstGraduate: _isFirstGraduate,
        isDifferentlyAbled: _isDifferentlyAbled,
        disabilityDetails: _disabilityController.text.trim(),
      ),
      contact: StudentContactDetails(
        primaryMobile: _primaryMobileController.text.trim(),
        alternateMobile: _alternateMobileController.text.trim(),
        personalEmail: _personalEmailController.text.trim(),
        emergencyContactName: _emergencyNameController.text.trim(),
        emergencyContactRelationship: _emergencyRelation ?? 'Father',
        emergencyContactNumber: _emergencyPhoneController.text.trim(),
        permanentAddress: StudentAddress(
          addressLine1: _permLine1Controller.text.trim(),
          addressLine2: _permLine2Controller.text.trim(),
          area: _permAreaController.text.trim(),
          city: _permCityController.text.trim(),
          district: _permDistrictController.text.trim(),
          state: _permStateController.text.trim(),
          pincode: _permPincodeController.text.trim(),
        ),
        sameAsPermanent: _sameAsPermanent,
        currentAddress: _sameAsPermanent
            ? StudentAddress(
                addressLine1: _permLine1Controller.text.trim(),
                addressLine2: _permLine2Controller.text.trim(),
                area: _permAreaController.text.trim(),
                city: _permCityController.text.trim(),
                district: _permDistrictController.text.trim(),
                state: _permStateController.text.trim(),
                pincode: _permPincodeController.text.trim(),
              )
            : StudentAddress(
                addressLine1: _currLine1Controller.text.trim(),
                addressLine2: _currLine2Controller.text.trim(),
                area: _currAreaController.text.trim(),
                city: _currCityController.text.trim(),
                district: _currDistrictController.text.trim(),
                state: _currStateController.text.trim(),
                pincode: _currPincodeController.text.trim(),
              ),
      ),
      parents: StudentParentDetails(
        father: ParentRecord(
          photoUrl: _fatherPhotoUrl,
          name: _fatherNameController.text.trim(),
          mobileNumber: _fatherPhoneController.text.trim(),
          email: _fatherEmailController.text.trim().isNotEmpty ? _fatherEmailController.text.trim() : null,
          qualification: _fatherQual ?? 'Bachelor Degree',
          occupation: _fatherOccupationController.text.trim(),
          annualIncome: _fatherIncome ?? '₹1,00,000 - ₹3,00,000',
        ),
        mother: ParentRecord(
          photoUrl: _motherPhotoUrl,
          name: _motherNameController.text.trim(),
          mobileNumber: _motherPhoneController.text.trim(),
          email: _motherEmailController.text.trim().isNotEmpty ? _motherEmailController.text.trim() : null,
          qualification: _motherQual ?? 'School',
          occupation: _motherOccupationController.text.trim(),
          annualIncome: _motherIncome ?? '₹1,00,000 - ₹3,00,000',
        ),
        guardian: _hasGuardian
            ? GuardianRecord(
                photoUrl: _guardianPhotoUrl,
                name: _guardianNameController.text.trim(),
                relationship: _guardianRelation ?? 'Guardian',
                mobileNumber: _guardianPhoneController.text.trim(),
                email: _guardianEmailController.text.trim().isNotEmpty ? _guardianEmailController.text.trim() : null,
                qualification: _guardianQualController.text.trim(),
                occupation: _guardianOccupationController.text.trim(),
                address: _guardianAddressController.text.trim(),
              )
            : null,
        parentAnnualIncome: _parentAnnualIncome ?? '₹3,00,000 - ₹5,00,000',
      ),
      education: StudentPreviousEducation(
        tenth: EducationRecord(
          institutionName: _tenthSchoolController.text.trim(),
          institutionAddress: _tenthAddressController.text.trim(),
          boardOrUniversity: _tenthBoard ?? 'State Board',
          medium: _effectiveTenthMedium,
          registerNumber: _tenthRegNoController.text.trim(),
          passingYear: _tenthYearController.text.trim(),
          totalMarks: double.tryParse(_tenthTotalController.text) ?? 500,
          marksObtained: double.tryParse(_tenthObtainedController.text) ?? 0,
          percentage: _tenthPercentage,
        ),
        twelfthOrDiploma: EducationRecord(
          institutionName: _twelfthSchoolController.text.trim(),
          institutionAddress: _twelfthAddressController.text.trim(),
          boardOrUniversity: _twelfthBoard ?? 'State Board',
          medium: _effectiveTwelfthMedium,
          registerNumber: _twelfthRegNoController.text.trim(),
          passingYear: _twelfthYearController.text.trim(),
          totalMarks: double.tryParse(_twelfthTotalController.text) ?? 600,
          marksObtained: double.tryParse(_twelfthObtainedController.text) ?? 0,
          percentage: _twelfthPercentage,
        ),
        hasDiploma: _hasDiploma,
        diploma: _hasDiploma
            ? EducationRecord(
                institutionName: _diplomaCollegeController.text.trim(),
                institutionAddress: _diplomaAddressController.text.trim(),
                boardOrUniversity: 'DOTE / Polytechnic Board',
                medium: _effectiveDiplomaMedium,
                registerNumber: _diplomaBranchController.text.trim(),
                passingYear: _diplomaYearController.text.trim(),
                totalMarks: double.tryParse(_diplomaTotalController.text) ?? 100,
                marksObtained: double.tryParse(_diplomaObtainedController.text) ?? 0,
                percentage: _diplomaPercentage,
              )
            : null,
      ),
      living: StudentLivingDetails(
        livingType: _selectedLivingType ?? LivingType.homeFamily,
        details: {
          'hostelName': _hostelNameController.text.trim(),
          'block': _hostelBlockController.text.trim(),
          'roomNo': _hostelRoomController.text.trim(),
          'pgName': _pgNameController.text.trim(),
          'pgAddress': _pgAddressController.text.trim(),
          'rentedAddress': _rentedAddressController.text.trim(),
          'roommateRegisterNumbers': _roommatesController.text.trim(),
          'roommates': _roommatesController.text.trim(),
          'ownerName': _accOwnerNameController.text.trim(),
          'ownerPhone': _accOwnerPhoneController.text.trim(),
          'address': _accAddressController.text.trim(),
        },
      ),
      transport: _isDayScholar
          ? StudentTransportDetails(
              mode: _transportMode ?? PrimaryTransportMode.BUS,
              modeDetails: _transportMode == PrimaryTransportMode.BUS
                  ? {
                      'busType': _busType,
                      'boardingPoint': _boardingPointController.text.trim(),
                      'busStop': _busStopController.text.trim(),
                      'pickupTime': _pickupTimeController.text.trim(),
                    }
                  : _transportMode == PrimaryTransportMode.BIKE
                      ? {
                          'vehicleType': _vehicleType,
                          'vehicleRegNo': _vehicleRegNoController.text.trim(),
                          'driverType': _driverType,
                          'parkingPermission': _parkingPermission,
                          'licenceAvailable': _licenceAvailable,
                        }
                      : {},
              oneWayDistanceKm: _distanceController.text.trim(),
              oneWayTravelTimeMinutes: _travelTimeController.text.trim(),
              usualArrivalTime: _arrivalTimeController.text.trim(),
              usualDepartureTime: _departureTimeController.text.trim(),
            )
          : null,
      documents: _activeDocuments,
    );

    final profileMap = profile.toMap();
    profileMap['verificationStatus'] = 'pending_hod';
    profileMap['profileCompletionStatus'] = 'submitted';
    profileMap['completionPercentage'] = _progressPercentage;

    await ref.read(firebaseFirestoreServiceProvider).submitFullStudentProfile(profileMap);

    final currentUser = ref.read(authServiceProvider).currentUser;
    if (currentUser != null) {
      final updatedMeta = Map<String, dynamic>.from(currentUser.metadata ?? {});
      updatedMeta['verificationStatus'] = 'pending_hod';
      updatedMeta['profileCompletionStatus'] = 'submitted';
      updatedMeta['submittedAt'] = DateTime.now().toIso8601String();
      if (_studentPhotoUrl != null && _studentPhotoUrl!.isNotEmpty) {
        updatedMeta['passportPhotoUrl'] = _studentPhotoUrl;
        updatedMeta['photoUrl'] = _studentPhotoUrl;
      }
      final parentsMap = Map<String, dynamic>.from(updatedMeta['parents'] as Map? ?? {});
      parentsMap['parentAnnualIncome'] = _parentAnnualIncome ?? '₹3,00,000 - ₹5,00,000';
      parentsMap['annualIncome'] = _parentAnnualIncome ?? '₹3,00,000 - ₹5,00,000';
      updatedMeta['parents'] = parentsMap;

      final updatedUser = currentUser.copyWith(
        profileImageUrl: (_studentPhotoUrl != null && _studentPhotoUrl!.isNotEmpty)
            ? _studentPhotoUrl
            : currentUser.profileImageUrl,
        metadata: updatedMeta,
      );
      await ref.read(authServiceProvider).updateUserProfile(updatedUser);
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.pop(context);
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 64),
            const SizedBox(height: 16),
            const Text(
              'Submitted to HOD Panel!',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Your 360° student profile details have been saved to the database and sent to the HOD Panel for official verification. Once approved by your HOD, you will receive an instant notification!',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Go to Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedStepBar() {
    final stepTitles = [
      'Personal Details',
      'Contact Details',
      'Parent Details',
      'Education',
      'Living Details',
      if (_isDayScholar) 'Transport Mode',
      'Documents',
      'Review & Submit',
    ];

    return Container(
      height: 48,
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: stepTitles.length,
        itemBuilder: (context, idx) {
          final stepNum = idx + 1;
          final isCurrent = stepNum == _displayStepNumber;
          final isPassed = stepNum < _displayStepNumber;

          return GestureDetector(
            onTap: () {
              if (isPassed) {
                setState(() => _currentStep = stepNum);
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    stepTitles[idx],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w600,
                      color: isCurrent
                          ? const Color(0xFF2563EB)
                          : (isPassed ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 3.5,
                    width: 75,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? const Color(0xFF2563EB)
                          : (isPassed ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.94),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Top Header Drag Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      onPressed: _currentStep > 1 ? _previousStep : () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A), size: 22),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Complete Student Profile',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A)),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton.icon(
                          onPressed: _isSavingDraft ? null : _saveDraft,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.save_as_rounded, size: 16, color: Color(0xFF2563EB)),
                          label: Text(_isSavingDraft ? 'Saving...' : 'Save Draft', style: const TextStyle(fontSize: 11.5, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 22),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _buildSegmentedStepBar(),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Step Body Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildCurrentStepBody(),
            ),
          ),

          // Fixed Bottom Control Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () {
                      if (_currentStep > 1) {
                        _previousStep();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back_rounded, size: 18),
                        SizedBox(width: 6),
                        Text('Back', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _currentStep == 8
                          ? (!_isConfirmed || _isSubmitting ? null : _submitFinalProfile)
                          : _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (_currentStep == 8 && !_isConfirmed)
                            ? const Color(0xFF94A3B8)
                            : AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: AppColors.primary.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              _currentStep == 8 ? 'Submit' : 'Next',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepBody() {
    switch (_currentStep) {
      case 1:
        return _buildStep1Personal();
      case 2:
        return _buildStep2ContactAddress();
      case 3:
        return _buildStep3ParentsGuardian();
      case 4:
        return _buildStep4Education();
      case 5:
        return _buildStep5Living();
      case 6:
        return _buildStep6Transport();
      case 7:
        return _buildStep7Documents();
      case 8:
        return _buildStep8Review();
      default:
        return _buildStep1Personal();
    }
  }

  Future<void> _pickStudentPhoto(ImageSource source) async {
    if (_isUploadingPhoto) return;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked == null) return;

      final user = ref.read(currentUserProvider).value ?? ref.read(authServiceProvider).currentUser;
      if (user == null) {
        throw Exception('User session not found.');
      }

      setState(() {
        _isUploadingPhoto = true;
      });

      final storageService = ref.read(storageServiceProvider);
      final existingUrl = _studentPhotoUrl ?? (user.profileImageUrl ?? user.metadata?['passportPhotoUrl'] ?? '').toString().trim();

      // 1. Upload to Firebase Storage and get download URL
      final uploadedUrl = await storageService.uploadProfilePhoto(
        userId: user.uid,
        file: File(picked.path),
      );

      // 2. Persist in Firestore
      try {
        final updatedMeta = Map<String, dynamic>.from(user.metadata ?? {});
        updatedMeta['passportPhotoUrl'] = uploadedUrl;
        updatedMeta['photoUrl'] = uploadedUrl;
        updatedMeta['profileImageUrl'] = uploadedUrl;
        final updatedUser = user.copyWith(
          profileImageUrl: uploadedUrl,
          metadata: updatedMeta,
        );
        await ref.read(authServiceProvider).updateUserProfile(updatedUser);
      } catch (e) {
        unawaited(storageService.deleteFile(uploadedUrl));
        rethrow;
      }

      // 3. Clean up old remote photo if different
      if (existingUrl.isNotEmpty &&
          existingUrl != uploadedUrl &&
          (existingUrl.contains('firebasestorage.googleapis.com') || existingUrl.contains('appspot.com'))) {
        unawaited(storageService.deleteFile(existingUrl));
      }

      if (mounted) {
        setState(() {
          _studentPhotoUrl = uploadedUrl;
          _isUploadingPhoto = false;
          final index = _uploadedDocuments.indexWhere((d) => d.id == 'doc_photo');
          final newDoc = StudentDocument(
            id: 'doc_photo',
            name: 'Student Passport Photo',
            isRequired: true,
            fileName: picked.name,
            fileUrl: uploadedUrl,
            status: 'uploaded',
          );
          if (index != -1) {
            _uploadedDocuments[index] = newDoc;
          } else {
            _uploadedDocuments.add(newDoc);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Student passport photo attached!'),
              ],
            ),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating photo: ${e.toString().replaceAll('Exception:', '').trim()}'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  void _showStudentPhotoPickerModal() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Student Passport Photo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('Upload a formal passport size photograph for official ID card and resume records.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEEF2FF),
                  child: Icon(Icons.camera_alt_rounded, color: Color(0xFF2563EB)),
                ),
                title: const Text('Take a Photo (Camera)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickStudentPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEEF2FF),
                  child: Icon(Icons.photo_library_rounded, color: Color(0xFF2563EB)),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickStudentPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── STEP 1: PERSONAL ──
  Widget _buildStep1Personal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader('Step 1: Personal Details', 'Verified details are locked. Enter your personal credentials.'),
        const SizedBox(height: 16),

        // Student Passport Photo Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: _showStudentPhotoPickerModal,
                child: Stack(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF2563EB), width: 2),
                        color: const Color(0xFFEEF2FF),
                      ),
                      child: ClipOval(
                        child: _isUploadingPhoto
                            ? const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF2563EB)),
                                ),
                              )
                            : (_studentPhotoUrl != null && _studentPhotoUrl!.isNotEmpty && (_studentPhotoUrl!.startsWith('http://') || _studentPhotoUrl!.startsWith('https://'))
                                ? Image.network(
                                    _studentPhotoUrl!,
                                    fit: BoxFit.cover,
                                    width: 72,
                                    height: 72,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 40, color: Color(0xFF2563EB)),
                                  )
                                : const Icon(Icons.person_add_alt_1_rounded, size: 36, color: Color(0xFF2563EB))),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Student Passport Photo *',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(width: 6),
                        if (_studentPhotoUrl != null && _studentPhotoUrl!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Attached ✓', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Upload clear real-time student face photo for college database, smart ID & resume.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.25),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        InkWell(
                          onTap: () => _pickStudentPhoto(ImageSource.camera),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.camera_alt_rounded, size: 14, color: Color(0xFF2563EB)),
                                SizedBox(width: 4),
                                Text('Camera', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                              ],
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => _pickStudentPhoto(ImageSource.gallery),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.photo_library_rounded, size: 14, color: Color(0xFF475569)),
                                SizedBox(width: 4),
                                Text('Gallery', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _buildReadOnlyField('Student Name', _nameController.text, Icons.verified_user_rounded),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildReadOnlyField('Register Number', _regNoController.text, Icons.badge_rounded)),
            const SizedBox(width: 12),
            Expanded(child: _buildReadOnlyField('Department', _deptController.text, Icons.school_rounded)),
          ],
        ),
        const SizedBox(height: 12),
        _buildReadOnlyField('College Email', _emailController.text, Icons.email_rounded),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 12),

        // Date of Birth DatePicker
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Date of Birth *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
            if (_dobError)
              const Text(
                '⚠️ Required field',
                style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime(2005, 5, 15),
              firstDate: DateTime(1990),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setState(() {
                _dob = DateFormat('dd/MM/yyyy').format(picked);
                _dobError = false;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: _dobError ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _dobError ? Colors.red : const Color(0xFFCBD5E1),
                width: _dobError ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _dob ?? 'Select Date of Birth',
                  style: TextStyle(
                    color: _dobError
                        ? Colors.red
                        : (_dob == null ? Colors.grey : Colors.black87),
                    fontSize: 14,
                    fontWeight: _dobError ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Icon(
                  Icons.calendar_month_rounded,
                  color: _dobError ? Colors.red : const Color(0xFF2563EB),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (_dobError)
          const Padding(
            padding: EdgeInsets.only(top: 4, left: 4),
            child: Text(
              'Please select your Date of Birth to proceed',
              style: TextStyle(color: Colors.red, fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
          ),
        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                'Gender',
                _gender,
                ['Male', 'Female', 'Other'],
                (val) => setState(() {
                  _gender = val;
                  _genderError = false;
                }),
                hasError: _genderError,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDropdown(
                'Blood Group',
                _bloodGroup,
                ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'],
                (val) => setState(() {
                  _bloodGroup = val;
                  _bloodGroupError = false;
                }),
                hasError: _bloodGroupError,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                'Religion',
                _religion,
                ['Hindu', 'Christian', 'Muslim', 'Sikh', 'Jain', 'Other'],
                (val) => setState(() {
                  _religion = val;
                  _religionError = false;
                }),
                hasError: _religionError,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDropdown(
                'Community',
                _community,
                ['OC', 'BC', 'MBC', 'SC', 'ST', 'DNC'],
                (val) => setState(() {
                  _community = val;
                  _communityError = false;
                }),
                hasError: _communityError,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildTextField(_casteController, 'Caste', 'e.g. Kongu Vellalar'),
        const SizedBox(height: 14),

        SwitchListTile(
          title: const Text('First Graduate in Family?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          value: _isFirstGraduate,
          onChanged: (val) => setState(() => _isFirstGraduate = val),
          activeThumbColor: const Color(0xFF2563EB),
        ),
        SwitchListTile(
          title: const Text('Differently Abled?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          value: _isDifferentlyAbled,
          onChanged: (val) => setState(() => _isDifferentlyAbled = val),
          activeThumbColor: const Color(0xFF2563EB),
        ),
        if (_isDifferentlyAbled)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _buildTextField(_disabilityController, 'Disability Details', 'Specify disability percentage & type'),
          ),
      ],
    );
  }

  // ── STEP 2: CONTACT & ADDRESS ──
  Widget _buildStep2ContactAddress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader('Step 2: Contact & Address', 'Provide emergency contacts and current living address.'),
        const SizedBox(height: 16),
        _buildTextField(
          _primaryMobileController,
          'Primary Mobile Number *',
          '+91 98765 43210',
          icon: Icons.phone_rounded,
          hasError: _primaryMobileError,
          errorText: 'Please enter Primary Mobile Number',
          onChanged: (val) {
            if (val.trim().isNotEmpty && _primaryMobileError) {
              setState(() => _primaryMobileError = false);
            }
          },
        ),
        const SizedBox(height: 12),
        _buildTextField(_alternateMobileController, 'Alternate Mobile Number (Optional)', '+91 98765 00000'),
        const SizedBox(height: 12),
        _buildTextField(_personalEmailController, 'Personal Email (Optional)', 'student@gmail.com'),
        const SizedBox(height: 16),

        const Text('Emergency Contact', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildTextField(_emergencyNameController, 'Contact Name', 'Father / Guardian Name')),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDropdown(
                'Relationship',
                _emergencyRelation,
                ['Father', 'Mother', 'Guardian', 'Uncle', 'Aunt', 'Brother', 'Sister', 'Other'],
                (val) => setState(() => _emergencyRelation = val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildTextField(_emergencyPhoneController, 'Emergency Phone Number', '+91 99944 00000'),
        const SizedBox(height: 20),

        const Text('Permanent Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
        const SizedBox(height: 8),
        _buildTextField(_permLine1Controller, 'Address Line 1', 'Door No, Street Name'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildTextField(_permCityController, 'City / Town', 'Karur')),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField(_permPincodeController, 'Pincode', '639002')),
          ],
        ),
        const SizedBox(height: 8),
        _buildTextField(_permStateController, 'State', 'Tamil Nadu'),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Current Address Same as Permanent?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Switch(
              value: _sameAsPermanent,
              onChanged: (val) => setState(() => _sameAsPermanent = val),
              activeThumbColor: const Color(0xFF2563EB),
            ),
          ],
        ),
        if (!_sameAsPermanent) ...[
          const SizedBox(height: 8),
          _buildTextField(_currLine1Controller, 'Current Address Line 1', 'Door No, Street Name'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildTextField(_currCityController, 'City / Town', 'Karur')),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField(_currPincodeController, 'Pincode', '639002')),
            ],
          ),
          const SizedBox(height: 8),
          _buildTextField(_currStateController, 'State', 'Tamil Nadu'),
        ],
      ],
    );
  }

  // ── STEP 3: PARENTS & GUARDIAN ──
  Widget _buildStep3ParentsGuardian() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader('Step 3: Parent & Guardian Details', 'Father & Mother details are required. Parent emails are OPTIONAL.'),
        const SizedBox(height: 16),

        // Father Card
        _buildParentCard(
          title: 'Father Details',
          nameCtrl: _fatherNameController,
          phoneCtrl: _fatherPhoneController,
          emailCtrl: _fatherEmailController,
          occupationCtrl: _fatherOccupationController,
          qualValue: _fatherQual ?? 'Bachelor Degree',
          incomeValue: _fatherIncome ?? '₹1,00,000 - ₹3,00,000',
          nameError: _fatherNameError,
          onNameChanged: (val) {
            if (val.trim().isNotEmpty && _fatherNameError) {
              setState(() => _fatherNameError = false);
            }
          },
          onQualChanged: (v) => setState(() => _fatherQual = v!),
          onIncomeChanged: (v) => setState(() => _fatherIncome = v!),
        ),
        const SizedBox(height: 16),

        // Mother Card
        _buildParentCard(
          title: 'Mother Details',
          nameCtrl: _motherNameController,
          phoneCtrl: _motherPhoneController,
          emailCtrl: _motherEmailController,
          occupationCtrl: _motherOccupationController,
          qualValue: _motherQual ?? 'School',
          incomeValue: _motherIncome ?? '₹1,00,000 - ₹3,00,000',
          nameError: _motherNameError,
          onNameChanged: (val) {
            if (val.trim().isNotEmpty && _motherNameError) {
              setState(() => _motherNameError = false);
            }
          },
          onQualChanged: (v) => setState(() => _motherQual = v!),
          onIncomeChanged: (v) => setState(() => _motherIncome = v!),
        ),
        const SizedBox(height: 16),

        // Parent / Family Annual Income Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF2563EB), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Total Parent / Family Annual Income *',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Combined gross annual income of parents from all sources for institutional records, scholarship eligibility, and fee concessions.',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.3),
              ),
              const SizedBox(height: 12),
              _buildDropdown(
                'Annual Income Range',
                _parentAnnualIncome ?? '₹3,00,000 - ₹5,00,000',
                [
                  'Below ₹1,00,000',
                  '₹1,00,000 - ₹3,00,000',
                  '₹3,00,000 - ₹5,00,000',
                  '₹5,00,000 - ₹8,00,000',
                  '₹8,00,000 - ₹12,00,000',
                  '₹12,00,000 - ₹20,00,000',
                  'Above ₹20,00,000',
                ],
                (v) => setState(() => _parentAnnualIncome = v!),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Guardian Card (Optional)
        SwitchListTile(
          title: const Text('+ Add Guardian Details (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
          value: _hasGuardian,
          onChanged: (val) => setState(() => _hasGuardian = val),
          activeThumbColor: const Color(0xFF2563EB),
        ),
        if (_hasGuardian) ...[
          const SizedBox(height: 8),
          _buildTextField(_guardianNameController, 'Guardian Name', 'Name'),
          const SizedBox(height: 8),
          _buildDropdown(
            'Relationship',
            _guardianRelation,
            ['Father', 'Mother', 'Guardian', 'Uncle', 'Aunt', 'Brother', 'Sister', 'Other'],
            (val) => setState(() => _guardianRelation = val),
          ),
          const SizedBox(height: 8),
          _buildTextField(_guardianPhoneController, 'Mobile Number', '+91 98765 00000'),
        ],
      ],
    );
  }

  Widget _buildParentCard({
    required String title,
    required TextEditingController nameCtrl,
    required TextEditingController phoneCtrl,
    required TextEditingController emailCtrl,
    required TextEditingController occupationCtrl,
    required String qualValue,
    required String incomeValue,
    bool nameError = false,
    ValueChanged<String>? onNameChanged,
    required ValueChanged<String?> onQualChanged,
    required ValueChanged<String?> onIncomeChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: nameError ? Colors.red : const Color(0xFFE2E8F0), width: nameError ? 1.5 : 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A))),
          const SizedBox(height: 12),
          _buildTextField(
            nameCtrl,
            'Full Name *',
            'Parent Name',
            hasError: nameError,
            errorText: 'Please enter parent name',
            onChanged: onNameChanged,
          ),
          const SizedBox(height: 8),
          _buildTextField(phoneCtrl, 'Mobile Number *', '+91 98765 43210'),
          const SizedBox(height: 8),
          _buildTextField(emailCtrl, 'Email Address (OPTIONAL)', 'parent@gmail.com'),
          const SizedBox(height: 8),
          _buildTextField(occupationCtrl, 'Occupation', 'Business / Agriculture'),
        ],
      ),
    );
  }

  // ── STEP 4: PREVIOUS EDUCATION ──
  Widget _buildStep4Education() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader('Step 4: Previous Education', 'Enter your compulsory 10th records and enable 12th or Diploma details.'),
        const SizedBox(height: 16),

        // 10th Standard Records (Compulsory for ALL students)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('10th Standard Records *', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                    child: const Text('Compulsory', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField(_tenthSchoolController, 'School Name *', 'Government / Private Higher Sec School'),
              const SizedBox(height: 8),
              _buildTextField(_tenthAddressController, 'School Address / Location *', 'e.g. Main Road, Karur, Tamil Nadu'),
              const SizedBox(height: 8),
              _buildMediumSelector(_tenthMedium, _tenthOtherMediumController, (val) => setState(() => _tenthMedium = val)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildTextField(_tenthObtainedController, 'Marks Obtained *', '450', onChanged: (_) => setState(_calculateEducationPercentages))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(_tenthTotalController, 'Total Marks *', '500', onChanged: (_) => setState(_calculateEducationPercentages))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 12th Standard Records Toggle & Section
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('+ Add 12th Standard / HSC Records', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A))),
                subtitle: const Text('Enable if student completed 12th Standard Higher Secondary school', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                value: _has12th,
                onChanged: (val) {
                  if (!val && !_hasDiploma) {
                    // Ensure at least one post-10th option remains active
                    setState(() {
                      _has12th = false;
                      _hasDiploma = true;
                    });
                  } else {
                    setState(() => _has12th = val);
                  }
                },
                activeThumbColor: const Color(0xFF2563EB),
              ),
              if (_has12th) ...[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(_twelfthSchoolController, 'Higher Sec School Name *', 'VSB Higher Sec School'),
                      const SizedBox(height: 8),
                      _buildTextField(_twelfthAddressController, 'School Address / Location *', 'e.g. Covai Road, Karur, Tamil Nadu'),
                      const SizedBox(height: 8),
                      _buildMediumSelector(_twelfthMedium, _twelfthOtherMediumController, (val) => setState(() => _twelfthMedium = val)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_twelfthObtainedController, 'Marks Obtained *', '540', onChanged: (_) => setState(_calculateEducationPercentages))),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField(_twelfthTotalController, 'Total Marks *', '600', onChanged: (_) => setState(_calculateEducationPercentages))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Polytechnic / Diploma Records Toggle & Section
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('+ Add Polytechnic / Diploma Records', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF1E40AF))),
                subtitle: const Text('Enable if student completed a Polytechnic Diploma course', style: TextStyle(fontSize: 11.5, color: Color(0xFF3B82F6))),
                value: _hasDiploma,
                onChanged: (val) {
                  if (!val && !_has12th) {
                    // Ensure at least one post-10th option remains active
                    setState(() {
                      _hasDiploma = false;
                      _has12th = true;
                    });
                  } else {
                    setState(() => _hasDiploma = val);
                  }
                },
                activeThumbColor: const Color(0xFF2563EB),
              ),
              if (_hasDiploma) ...[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(_diplomaCollegeController, 'Polytechnic College Name *', 'e.g. VSB Polytechnic College'),
                      const SizedBox(height: 8),
                      _buildTextField(_diplomaBranchController, 'Diploma Branch / Specialization *', 'e.g. Diploma in Computer Engineering'),
                      const SizedBox(height: 8),
                      _buildTextField(_diplomaAddressController, 'College Address / Location *', 'e.g. Covai Road, Karur, Tamil Nadu'),
                      const SizedBox(height: 8),
                      _buildMediumSelector(_diplomaMedium, _diplomaOtherMediumController, (val) => setState(() => _diplomaMedium = val)),
                      const SizedBox(height: 12),

                      // Evaluation Mode Selector (Percentage vs Grade)
                      const Text(
                        'Diploma Evaluation Mode *',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E40AF)),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Percentage (%)'),
                            selected: _diplomaEvalMode == 'Percentage',
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _diplomaEvalMode = 'Percentage';
                                  if (_diplomaTotalController.text.contains('Class') || _diplomaTotalController.text.contains('Grade')) {
                                    _diplomaTotalController.text = '100';
                                  }
                                  if (_diplomaObtainedController.text.isEmpty || _diplomaObtainedController.text == 'A+') {
                                    _diplomaObtainedController.text = '88.5';
                                  }
                                  _calculateEducationPercentages();
                                });
                              }
                            },
                            selectedColor: const Color(0xFF2563EB),
                            labelStyle: TextStyle(
                              color: _diplomaEvalMode == 'Percentage' ? Colors.white : const Color(0xFF0F172A),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Grade'),
                            selected: _diplomaEvalMode == 'Grade',
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _diplomaEvalMode = 'Grade';
                                  if (_diplomaObtainedController.text.isEmpty || double.tryParse(_diplomaObtainedController.text) != null) {
                                    _diplomaObtainedController.text = _selectedDiplomaGrade;
                                  }
                                  _diplomaTotalController.text = 'First Class with Distinction';
                                  _calculateEducationPercentages();
                                });
                              }
                            },
                            selectedColor: const Color(0xFF2563EB),
                            labelStyle: TextStyle(
                              color: _diplomaEvalMode == 'Grade' ? Colors.white : const Color(0xFF0F172A),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_diplomaEvalMode == 'Grade') ...[
                        Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Grade Obtained *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF0F172A))),
                                  const SizedBox(height: 4),
                                  DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    initialValue: ['O', 'A+', 'A', 'B+', 'B', 'C'].contains(_diplomaObtainedController.text.trim())
                                        ? _diplomaObtainedController.text.trim()
                                        : 'A+',
                                    decoration: InputDecoration(
                                      isDense: true,
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'O', child: Text('O Grade', overflow: TextOverflow.ellipsis)),
                                      DropdownMenuItem(value: 'A+', child: Text('A+ Grade', overflow: TextOverflow.ellipsis)),
                                      DropdownMenuItem(value: 'A', child: Text('A Grade', overflow: TextOverflow.ellipsis)),
                                      DropdownMenuItem(value: 'B+', child: Text('B+ Grade', overflow: TextOverflow.ellipsis)),
                                      DropdownMenuItem(value: 'B', child: Text('B Grade', overflow: TextOverflow.ellipsis)),
                                      DropdownMenuItem(value: 'C', child: Text('C Grade', overflow: TextOverflow.ellipsis)),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _selectedDiplomaGrade = val;
                                          _diplomaObtainedController.text = val;
                                          _calculateEducationPercentages();
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 5,
                              child: _buildTextField(_diplomaTotalController, 'Class / Division *', 'First Class Distinction'),
                            ),
                          ],
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                _diplomaObtainedController,
                                'Percentage / Marks Obtained *',
                                '88.5',
                                onChanged: (_) => setState(_calculateEducationPercentages),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                _diplomaTotalController,
                                'Total Marks / Out of *',
                                '100',
                                onChanged: (_) => setState(_calculateEducationPercentages),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      _buildTextField(_diplomaYearController, 'Year of Passing', '2023'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMediumSelector(
    String selectedMedium,
    TextEditingController otherController,
    ValueChanged<String> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Medium of Instruction *',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 6),
        Row(
          children: ['English', 'Tamil', 'Other'].map((m) {
            final isSelected = selectedMedium == m;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(m),
                selected: isSelected,
                onSelected: (val) {
                  if (val) onChanged(m);
                },
                selectedColor: const Color(0xFF2563EB),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF0F172A),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            );
          }).toList(),
        ),
        if (selectedMedium == 'Other') ...[
          const SizedBox(height: 8),
          _buildTextField(
            otherController,
            'Specify Medium of Instruction *',
            'e.g. Hindi, Telugu, Malayalam, French',
            onChanged: (_) => setState(() {}),
          ),
        ],
      ],
    );
  }

  // ── STEP 5: LIVING & ACCOMMODATION ──
  Widget _buildStep5Living() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader('Step 5: Living & Accommodation', 'Where are you currently staying during college term?'),
        const SizedBox(height: 16),

        _buildLivingOptionCard(LivingType.collegeHostel, 'College Hostel', 'Official VSB Hostel Resident'),
        _buildLivingOptionCard(LivingType.homeFamily, 'Home with Family', 'Staying with parents / day scholar'),
        _buildLivingOptionCard(LivingType.pgHostel, 'PG / Private Hostel', 'Private hostel accommodation'),
        _buildLivingOptionCard(LivingType.rentedHouse, 'Rented House / Room', 'Rented house with friends'),

        const SizedBox(height: 16),
        if (_selectedLivingType == LivingType.collegeHostel) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_rounded, color: Color(0xFF2563EB), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hostel Resident Notice: Step 6 (Day Scholar Transport) will be automatically skipped.',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildTextField(_hostelNameController, 'Hostel Name', 'VSB Men\'s Hostel'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildTextField(_hostelBlockController, 'Block', 'Block A')),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField(_hostelRoomController, 'Room No', '304')),
            ],
          ),
        ],

        if (_selectedLivingType == LivingType.pgHostel) ...[
          const SizedBox(height: 12),
          _buildTextField(_pgNameController, 'Name of PG / Private Hostel *', 'e.g. Sri Sai Men\'s PG'),
          const SizedBox(height: 8),
          _buildTextField(_pgAddressController, 'PG Address / Location *', 'e.g. Covai Road, Near VSB Campus, Karur'),
          const SizedBox(height: 8),
          _buildTextField(_roommatesController, 'Roommate Register Numbers', 'e.g. 7378211CS101, 7378211CS105 or Single Room'),
        ],

        if (_selectedLivingType == LivingType.rentedHouse) ...[
          const SizedBox(height: 12),
          _buildTextField(_rentedAddressController, 'Rented House Address / Location *', 'e.g. 12/A, Gandhigramam 3rd Street, Karur'),
          const SizedBox(height: 8),
          _buildTextField(_roommatesController, 'Roommate Register Numbers (comma separated) *', 'e.g. 7378211CS101, 7378211CS105 or Family'),
        ],
      ],
    );
  }

  Widget _buildLivingOptionCard(LivingType type, String title, String subtitle) {
    final isSelected = _selectedLivingType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedLivingType = type),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0), width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isSelected ? const Color(0xFF1E40AF) : const Color(0xFF0F172A))),
                Text(subtitle, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── STEP 6: DAY SCHOLAR TRANSPORT (STRICTLY ONLY BUS, BIKE, WALK) ──
  Widget _buildStep6Transport() {
    if (!_isDayScholar) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader('Step 6: Transport Mode', 'Transport configuration for College Hostel residents.'),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Row(
              children: [
                Icon(Icons.bed_rounded, color: Color(0xFF2563EB), size: 36),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'College Hostel Resident',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E40AF)),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Day Scholar bus/vehicle transport setup is not required because you selected College Hostel in Step 5. Tap Next below to proceed to Step 7 (Certificate Documents Upload).',
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF3B82F6), height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader('Step 6: Day Scholar Transport Mode', 'Select your primary mode of travel to college.'),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(child: _buildTransportChip(PrimaryTransportMode.BUS, 'Bus', Icons.directions_bus_rounded)),
            const SizedBox(width: 8),
            Expanded(child: _buildTransportChip(PrimaryTransportMode.BIKE, 'Bike', Icons.two_wheeler_rounded)),
            const SizedBox(width: 8),
            Expanded(child: _buildTransportChip(PrimaryTransportMode.WALK, 'Walk', Icons.directions_walk_rounded)),
          ],
        ),
        const SizedBox(height: 16),

        if (_transportMode == PrimaryTransportMode.BUS) ...[
          _buildDropdown('Bus Type', _busType, ['College Bus', 'Public Bus'], (val) => setState(() => _busType = val)),
          const SizedBox(height: 8),
          _buildTextField(_boardingPointController, 'Boarding Point', 'Gandhigramam'),
        ],

        if (_transportMode == PrimaryTransportMode.BIKE) ...[
          _buildDropdown('Vehicle Type', _vehicleType, ['Bike', 'Scooter'], (val) => setState(() => _vehicleType = val)),
          const SizedBox(height: 8),
          _buildTextField(_vehicleRegNoController, 'Vehicle Registration Number', 'TN 47 AB 1234'),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('College Parking Permission Required?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            value: _parkingPermission,
            onChanged: (v) => setState(() => _parkingPermission = v),
            activeThumbColor: const Color(0xFF2563EB),
          ),
        ],
      ],
    );
  }

  Widget _buildTransportChip(PrimaryTransportMode mode, String label, IconData icon) {
    final isSelected = _transportMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _transportMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : const Color(0xFF475569)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDocument(StudentDocument doc) async {
    try {
      final isPhoto = doc.id == 'doc_photo';
      final allowedExts = isPhoto ? ['jpg', 'jpeg', 'png'] : ['pdf', 'jpg', 'jpeg', 'png'];

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExts,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final sizeMb = (file.size / (1024 * 1024)).toStringAsFixed(1);
        final sizeStr = sizeMb == '0.0' ? '0.5 MB' : '$sizeMb MB';
        final displayName = '${file.name} ($sizeStr)';

        setState(() {
          final idx = _uploadedDocuments.indexWhere((d) => d.id == doc.id);
          final newDoc = StudentDocument(
            id: doc.id,
            name: doc.name,
            isRequired: doc.isRequired,
            fileName: displayName,
            fileUrl: file.path ?? 'https://unisphere.edu/docs/${file.name}',
            status: 'uploaded',
          );
          if (idx != -1) {
            _uploadedDocuments[idx] = newDoc;
          } else {
            _uploadedDocuments.add(newDoc);
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking document: $e');
    }
  }

  void _removeDocument(StudentDocument doc) {
    setState(() {
      final idx = _uploadedDocuments.indexWhere((d) => d.id == doc.id);
      if (idx != -1) {
        _uploadedDocuments[idx] = StudentDocument(
          id: doc.id,
          name: doc.name,
          isRequired: doc.isRequired,
          fileName: '',
          fileUrl: '',
          status: 'pending',
        );
      }
    });
  }

  // ── STEP 7: DOCUMENTS UPLOAD (REBUILT CLEAN & CRASH-FREE) ──
  Widget _buildStep7Documents() {
    final docs = _activeDocuments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          'Step 7: Documents Upload',
          'Upload clear PDF or image scans of required certificates for college verification.',
        ),
        const SizedBox(height: 16),

        ...docs.map((doc) {
          final isUploaded = doc.fileName.isNotEmpty;

          return Container(
            key: ValueKey('doc_${doc.id}'),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isUploaded ? const Color(0xFFF0FDF4) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isUploaded ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isUploaded ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    isUploaded ? Icons.check_circle_rounded : Icons.cloud_upload_rounded,
                    color: isUploaded ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              doc.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (doc.isRequired)
                            const Text(
                              ' *',
                              style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isUploaded ? '✅ ${doc.fileName}' : 'Required formats: PDF, JPG, PNG (Max 5MB)',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isUploaded ? FontWeight.w700 : FontWeight.normal,
                          color: isUploaded ? const Color(0xFF15803D) : const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (isUploaded)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      onTap: () => _removeDocument(doc),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF64748B)),
                      ),
                    ),
                  ),
                ElevatedButton(
                  onPressed: () => _pickDocument(doc),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isUploaded ? const Color(0xFF0F172A) : AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    minimumSize: const Size(64, 36),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    isUploaded ? 'Change' : 'Upload',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── STEP 8: REVIEW & SUBMIT ──
  Widget _buildStep8Review() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader('Step 8: Review & Submit', 'Confirm all profile summary details before final submission.'),
        const SizedBox(height: 16),

        _buildSummaryCard('Personal Details', [
          'Name: ${_nameController.text}',
          'DOB: ${_dob ?? 'Not selected'}',
          'Gender: ${_gender ?? 'Not selected'}',
          'Blood Group: ${_bloodGroup ?? 'Not selected'}',
        ]),
        const SizedBox(height: 12),
        _buildSummaryCard('Contact & Address', [
          'Mobile: ${_primaryMobileController.text}',
          'Permanent: ${_permLine1Controller.text}, ${_permCityController.text}, ${_permStateController.text} - ${_permPincodeController.text}',
        ]),
        const SizedBox(height: 12),
        _buildSummaryCard('Parents Details', [
          'Father: ${_fatherNameController.text} (${_fatherPhoneController.text})',
          'Mother: ${_motherNameController.text} (${_motherPhoneController.text})',
        ]),
        const SizedBox(height: 12),
        _buildSummaryCard('Previous Education', [
          '10th Standard: ${_tenthSchoolController.text.isNotEmpty ? _tenthSchoolController.text : "Recorded"} (${_tenthAddressController.text.isNotEmpty ? _tenthAddressController.text : "Address recorded"}) (${_tenthObtainedController.text}/${_tenthTotalController.text}) - Medium: $_effectiveTenthMedium',
          if (_has12th)
            '12th Standard: ${_twelfthSchoolController.text.isNotEmpty ? _twelfthSchoolController.text : "Recorded"} (${_twelfthAddressController.text.isNotEmpty ? _twelfthAddressController.text : "Address recorded"}) (${_twelfthObtainedController.text}/${_twelfthTotalController.text}) - Medium: $_effectiveTwelfthMedium',
          if (_hasDiploma)
            'Diploma / Polytechnic: ${_diplomaCollegeController.text.isNotEmpty ? _diplomaCollegeController.text : "Recorded"} (${_diplomaBranchController.text}) (${_diplomaAddressController.text.isNotEmpty ? _diplomaAddressController.text : "Address recorded"}) - ${_diplomaObtainedController.text}/${_diplomaTotalController.text} ($_diplomaEvalMode, Medium: $_effectiveDiplomaMedium)',
        ]),
        const SizedBox(height: 12),
        _buildSummaryCard('Living & Transport', [
          'Staying Type: ${_selectedLivingType?.name ?? 'Not selected'}',
          if (_selectedLivingType == LivingType.pgHostel) ...[
            'PG Name: ${_pgNameController.text.isNotEmpty ? _pgNameController.text : "Not specified"}',
            'PG Location: ${_pgAddressController.text.isNotEmpty ? _pgAddressController.text : "Not specified"}',
            if (_roommatesController.text.isNotEmpty) 'Roommates: ${_roommatesController.text}',
          ],
          if (_selectedLivingType == LivingType.rentedHouse) ...[
            'Rented Address: ${_rentedAddressController.text.isNotEmpty ? _rentedAddressController.text : "Not specified"}',
            'Living With: ${_roommatesController.text.isNotEmpty ? _roommatesController.text : "Not specified"}',
          ],
          if (_isDayScholar) 'Transport Mode: ${_transportMode?.name ?? 'Not selected'}',
        ]),
        const SizedBox(height: 20),

        CheckboxListTile(
          value: _isConfirmed,
          onChanged: (v) => setState(() => _isConfirmed = v ?? false),
          title: const Text(
            'I confirm that all information provided is accurate and true to my knowledge.',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
          ),
          activeColor: const Color(0xFF2563EB),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, List<String> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A))),
          const SizedBox(height: 8),
          ...items.map((it) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $it', style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.3)),
              )),
        ],
      ),
    );
  }

  Widget _buildStepHeader(String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16.5, color: Color(0xFF0F172A))),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ],
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: _fillMockData,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, size: 14, color: Color(0xFF2563EB)),
                SizedBox(width: 4),
                Text('Fill Mock Data', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return TextFormField(
      initialValue: value,
      enabled: false,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF2563EB), size: 18),
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    String hint, {
    IconData? icon,
    bool hasError = false,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: hasError ? Colors.red : const Color(0xFF64748B),
            ),
          ),
        ),
        TextFormField(
          controller: ctrl,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5, fontWeight: FontWeight.w400),
            prefixIcon: icon != null ? Icon(icon, color: hasError ? Colors.red : const Color(0xFF2563EB), size: 18) : null,
            filled: true,
            fillColor: hasError ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9),
            errorText: hasError ? (errorText ?? 'Required field') : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: hasError ? Colors.red : const Color(0xFFE2E8F0),
                width: hasError ? 1.5 : 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: hasError ? Colors.red : const Color(0xFF2563EB),
                width: hasError ? 2.0 : 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged, {
    bool hasError = false,
  }) {
    final validValue = (value != null && items.contains(value)) ? value : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: hasError ? Colors.red : const Color(0xFF64748B),
            ),
          ),
        ),
        DropdownButtonFormField<String>(
          initialValue: validValue,
          isExpanded: true,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
          hint: Text(
            'Select $label',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: hasError ? Colors.red : const Color(0xFF94A3B8),
              fontSize: 13.5,
              fontWeight: hasError ? FontWeight.bold : FontWeight.w400,
            ),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: hasError ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: hasError ? Colors.red : const Color(0xFFE2E8F0),
                width: hasError ? 1.5 : 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: hasError ? Colors.red : const Color(0xFF2563EB),
                width: hasError ? 2.0 : 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: items
              .map((it) => DropdownMenuItem(
                    value: it,
                    child: Text(it, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
