void main() { 
  var r = RegExp(r'\b(?=.*\d)[A-Z0-9]{10,16}\b'); 
  print(r.hasMatch('INSTALLMENT')); 
  print(r.hasMatch('SMARTSCHOOL')); 
  print(r.hasMatch('TXN101062026001')); 
  print(r.hasMatch('123456789012')); 
}
