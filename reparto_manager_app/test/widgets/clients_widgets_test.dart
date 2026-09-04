import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reparto_manager_app/core/design_system/design_system.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapWithMaterial(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('Atomic Clients Widgets Tests', () {
    testWidgets('1. ClientListItem renderiza nombre, apodo, zona, dirección y saldo', (tester) async {
      bool tapped = false;
      bool edited = false;
      bool deleted = false;
      bool passed = false;

      await tester.pumpWidget(
        wrapWithMaterial(
          ClientListItem(
            name: 'Carlos Gómez',
            nickname: 'El Pela',
            address: 'San Martín 1420',
            zone: 'Centro',
            balance: 24500,
            isContinuousSchedule: true,
            isVisited: false,
            isPassed: false,
            onTap: () => tapped = true,
            onEdit: () => edited = true,
            onDelete: () => deleted = true,
            onTogglePassed: () => passed = true,
          ),
        ),
      );

      expect(find.text('Carlos Gómez (El Pela)'), findsOneWidget);
      expect(find.text('Centro'), findsOneWidget);
      expect(find.text('San Martín 1420'), findsOneWidget);
      expect(find.textContaining('24.500'), findsOneWidget);
      expect(find.byIcon(Icons.wb_sunny_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(passed, isTrue);

      await tester.tap(find.byIcon(Icons.edit_outlined));
      expect(edited, isTrue);

      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      expect(deleted, isTrue);

      await tester.tap(find.text('Carlos Gómez (El Pela)'));
      expect(tapped, isTrue);
    });

    testWidgets('2. ClientListItem en estado pasado muestra botón deshacer', (tester) async {
      bool undoPassed = false;

      await tester.pumpWidget(
        wrapWithMaterial(
          ClientListItem(
            name: 'Panadería San Cayetano',
            balance: 12000,
            isContinuousSchedule: false,
            isPassed: true,
            onUndoPassed: () => undoPassed = true,
          ),
        ),
      );

      expect(find.text('• PASADO'), findsOneWidget);
      expect(find.text('Cierra mediodía'), findsOneWidget);
      expect(find.byIcon(Icons.undo_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.undo_rounded));
      expect(undoPassed, isTrue);
    });

    testWidgets('3. ClientCardItem renderiza correctamente en modo tarjeta', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterial(
          ClientCardItem(
            name: 'Almacén Don Tito',
            nickname: 'Tito',
            address: 'Belgrano 340',
            zone: 'Sur',
            balance: -5000,
            isContinuousSchedule: false,
            isVisited: true,
          ),
        ),
      );

      expect(find.text('Almacén Don Tito (Tito)'), findsOneWidget);
      expect(find.text('Sur'), findsOneWidget);
      expect(find.text('Belgrano 340'), findsOneWidget);
      expect(find.text('Cierra mediodía'), findsOneWidget);
      expect(find.textContaining('5.000'), findsOneWidget);
    });

    testWidgets('4. ClientsBottomBar muestra total adeudado y botón de agregar', (tester) async {
      bool addTapped = false;

      await tester.pumpWidget(
        wrapWithMaterial(
          ClientsBottomBar(
            totalDebt: 36500,
            onAddClient: () => addTapped = true,
          ),
        ),
      );

      expect(find.text('+ AGREGAR CLIENTE'), findsOneWidget);
      expect(find.text('Total Adeudado:'), findsOneWidget);
      expect(find.textContaining('36.500'), findsOneWidget);

      await tester.tap(find.text('+ AGREGAR CLIENTE'));
      expect(addTapped, isTrue);
    });
  });
}
