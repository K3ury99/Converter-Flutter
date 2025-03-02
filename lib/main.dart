import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

void main() {
  runApp(MyApp());
}

/// Aplicación principal con rutas para conversión e histórico.
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Conversor de Monedas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[200],
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white, // Texto en blanco
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => ConversionScreen(),
        '/history': (context) => HistoryScreen(),
      },
    );
  }
}

/// Pantalla principal para convertir monedas.
class ConversionScreen extends StatefulWidget {
  @override
  _ConversionScreenState createState() => _ConversionScreenState();
}

class _ConversionScreenState extends State<ConversionScreen> {
  final TextEditingController _amountController = TextEditingController();
  Map<String, dynamic> _currencies = {};
  String? _fromCurrency;
  String? _toCurrency;
  DateTime? _selectedDate;
  String _result = '';

  @override
  void initState() {
    super.initState();
    _fetchCurrencies();
  }

  Future<void> _fetchCurrencies() async {
    final url = Uri.parse('https://api.frankfurter.app/currencies');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _currencies = data;
          _fromCurrency = _currencies.keys.first;
          _toCurrency = _currencies.keys.elementAt(1);
        });
      }
    } catch (e) {
      setState(() => _result = 'Error al cargar las monedas.');
    }
  }

  /// Construye la lista de DropdownMenuItem ordenando las monedas preferidas.
  List<DropdownMenuItem<String>> _buildCurrencyItems() {
    if (_currencies.isEmpty) return [];
    List<String> codes = _currencies.keys.toList();
    List<String> preferred = ["USD", "CAD", "EUR", "GBP"];
    List<String> preferredCurrencies = [];
    List<String> otherCurrencies = [];
    for (var code in codes) {
      if (preferred.contains(code))
        preferredCurrencies.add(code);
      else
        otherCurrencies.add(code);
    }
    preferredCurrencies.sort((a, b) => preferred.indexOf(a).compareTo(preferred.indexOf(b)));
    otherCurrencies.sort();
    List<String> sortedCodes = [...preferredCurrencies, ...otherCurrencies];
    return sortedCodes.map((code) {
      return DropdownMenuItem(
        value: code,
        child: Text('$code - ${_currencies[code]}'),
      );
    }).toList();
  }

  Future<void> _convert() async {
    final amountText = _amountController.text;
    if (amountText.isEmpty || _fromCurrency == null || _toCurrency == null) return;
    final amountValue = double.tryParse(amountText) ?? 0.0;
    String urlStr;
    if (_selectedDate != null) {
      String dateStr =
          "${_selectedDate!.year.toString().padLeft(4, '0')}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";
      urlStr = "https://api.frankfurter.app/$dateStr?amount=$amountValue&from=$_fromCurrency&to=$_toCurrency";
    } else {
      urlStr = "https://api.frankfurter.app/latest?amount=$amountValue&from=$_fromCurrency&to=$_toCurrency";
    }
    try {
      final response = await http.get(Uri.parse(urlStr));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rateValue = data['rates'][_toCurrency];
        // Formatear números con comas y dos decimales.
        final formatter = NumberFormat("#,##0.00", "en_US");
        final formattedAmount = formatter.format(amountValue);
        final formattedRate = formatter.format(rateValue);
        setState(() {
          _result = "$formattedAmount $_fromCurrency = $formattedRate $_toCurrency";
        });
      } else {
        setState(() => _result = 'Error en la conversión.');
      }
    } catch (e) {
      setState(() => _result = 'Error al conectarse a la API.');
    }
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1999),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Conversor de Monedas',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo, Colors.indigoAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey[200]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: EdgeInsets.all(16),
        child: _currencies.isEmpty
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Botón "Histórico" arriba a la derecha, fuera del Card.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/history'),
                          icon: Icon(Icons.history, color: Colors.white),
                          label: Text('Histórico'),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      margin: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Cantidad',
                                prefixIcon: Icon(Icons.attach_money),
                              ),
                            ),
                            SizedBox(height: 16),
                            // Dropdown de Moneda Base.
                            DropdownButtonFormField<String>(
                              value: _fromCurrency,
                              decoration: InputDecoration(
                                labelText: 'Moneda Base',
                                prefixIcon: Icon(Icons.account_balance_wallet),
                              ),
                              items: _buildCurrencyItems(),
                              onChanged: (value) => setState(() => _fromCurrency = value),
                            ),
                            SizedBox(height: 16),
                            // Dropdown de Moneda Destino.
                            DropdownButtonFormField<String>(
                              value: _toCurrency,
                              decoration: InputDecoration(
                                labelText: 'Moneda Destino',
                                prefixIcon: Icon(Icons.account_balance),
                              ),
                              items: _buildCurrencyItems(),
                              onChanged: (value) => setState(() => _toCurrency = value),
                            ),
                            SizedBox(height: 16),
                            // Selector de fecha.
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _pickDate,
                                    icon: Icon(Icons.date_range),
                                    label: Text(_selectedDate == null
                                        ? 'Selecciona una fecha (opcional)'
                                        : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _convert,
                              child: Text('Convertir'),
                            ),
                            SizedBox(height: 16),
                            if (_result.isNotEmpty) ...[
                              Center(
                                child: Text(
                                  _result,
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                                ),
                              ),
                              SizedBox(height: 8),
                              Center(
                                child: Text(
                                  'Fecha de conversión: ' +
                                      (_selectedDate != null
                                          ? "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}"
                                          : "Última tasa"),
                                  style: TextStyle(fontSize: 16, color: Colors.indigo),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Pantalla para mostrar el historial de tasas de cambio.
class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Map<String, dynamic> _currencies = {};
  String? _baseCurrency;
  Map<String, dynamic> _rates = {};
  bool _isLoading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchCurrencies();
  }

  Future<void> _fetchCurrencies() async {
    final url = Uri.parse('https://api.frankfurter.app/currencies');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _currencies = data;
          _baseCurrency = _currencies.keys.first;
        });
      }
    } catch (e) {
      setState(() => _error = 'Error al cargar las monedas.');
    }
  }

  /// Construye la lista de DropdownMenuItem ordenando las monedas preferidas.
  List<DropdownMenuItem<String>> _buildCurrencyItems() {
    if (_currencies.isEmpty) return [];
    List<String> codes = _currencies.keys.toList();
    List<String> preferred = ["USD", "CAD", "EUR", "GBP"];
    List<String> preferredCurrencies = [];
    List<String> otherCurrencies = [];
    for (var code in codes) {
      if (preferred.contains(code))
        preferredCurrencies.add(code);
      else
        otherCurrencies.add(code);
    }
    preferredCurrencies.sort((a, b) => preferred.indexOf(a).compareTo(preferred.indexOf(b)));
    otherCurrencies.sort();
    List<String> sortedCodes = [...preferredCurrencies, ...otherCurrencies];
    return sortedCodes.map((code) {
      return DropdownMenuItem(
        value: code,
        child: Text('$code - ${_currencies[code]}'),
      );
    }).toList();
  }

  Future<void> _loadHistory() async {
    if (_baseCurrency == null) return;
    setState(() {
      _isLoading = true;
      _rates = {};
      _error = '';
    });
    final url = Uri.parse('https://api.frankfurter.app/latest?from=$_baseCurrency');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() => _rates = data['rates']);
      } else {
        setState(() => _error = 'Error al cargar el historial.');
      }
    } catch (e) {
      setState(() => _error = 'Error al conectarse a la API.');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historial de Tasa de Cambio',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo, Colors.indigoAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey[200]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: EdgeInsets.all(16),
        child: _currencies.isEmpty
            ? Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    value: _baseCurrency,
                    decoration: InputDecoration(
                      labelText: 'Moneda Base',
                      prefixIcon: Icon(Icons.account_balance_wallet),
                    ),
                    items: _buildCurrencyItems(),
                    onChanged: (value) => setState(() => _baseCurrency = value),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadHistory,
                    child: Text('Cargar Historial'),
                  ),
                  SizedBox(height: 16),
                  _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : _error.isNotEmpty
                          ? Center(child: Text(_error, style: TextStyle(color: Colors.red)))
                          : Expanded(
                              child: Card(
                                elevation: 3,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ListView.builder(
                                  itemCount: _rates.keys.length,
                                  itemBuilder: (context, index) {
                                    String key = _rates.keys.elementAt(index);
                                    return ListTile(
                                      leading: Icon(Icons.monetization_on),
                                      title: Text('$_baseCurrency → $key'),
                                      trailing: Text('${_rates[key]}'),
                                    );
                                  },
                                ),
                              ),
                            ),
                ],
              ),
      ),
    );
  }
}
