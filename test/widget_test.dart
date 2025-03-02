import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyect_6/main.dart';

void main() {
  testWidgets('La aplicación se carga correctamente y navega a la pantalla de historial', (WidgetTester tester) async {
    // Construir la aplicación
    await tester.pumpWidget(MyApp());

    // Verificar que la pantalla de conversión se muestre
    expect(find.text('Conversor de Monedas'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Convertir'), findsOneWidget);
    
    // Verificar que existe el icono para acceder al historial
    expect(find.byIcon(Icons.history), findsOneWidget);

    // Simular el tap en el icono de historial y esperar la navegación
    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();

    // Verificar que se muestra la pantalla de historial
    expect(find.text('Historial de Tasa de Cambio'), findsOneWidget);
  });
}
