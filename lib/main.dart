import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestor Financiero',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: FinancialManager(),
    );
  }
}

class FinancialManager extends StatefulWidget {
  const FinancialManager({super.key});

  @override
  _FinancialManagerState createState() => _FinancialManagerState();
}

class _FinancialManagerState extends State<FinancialManager> {
  final List<Map<String, dynamic>> movements = [];
  double saldo = 0;

  TextEditingController descriptionController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  String selectedType = 'Ingreso';
  bool _isLoading = false;

  // Función para agregar un movimiento sin confirmación
  void addMovement() {
    final description = descriptionController.text;
    final amountText = amountController.text;
    if (description.isEmpty || amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, ingresa todos los campos.')),
      );
      return;
    }

    double amount = double.tryParse(amountText) ?? 0;
    if (amount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, ingresa un monto válido.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        if (selectedType == 'Gasto') amount = -amount; // Si es un gasto, lo convertimos en negativo
        movements.add({
          'description': description,
          'amount': amount,
          'type': selectedType,
          'date': DateTime.now(),
        });
        saldo += amount; // Actualizamos el saldo
        _isLoading = false;
      });

      descriptionController.clear();
      amountController.clear();
    });
  }

  // Función para eliminar un movimiento específico
  void deleteMovement(int index) {
    setState(() {
      saldo -= movements[index]['amount']; // Actualizamos el saldo, restando el valor del movimiento
      movements.removeAt(index); // Eliminamos el movimiento de la lista
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Movimiento eliminado.')),
    );
  }

  // Función para editar un movimiento específico
  void editMovement(int index) {
    // Cargar los valores del movimiento en los campos de texto para edición
    descriptionController.text = movements[index]['description'];
    amountController.text = movements[index]['amount'].toString();
    selectedType = movements[index]['type'];

    // Mostrar un formulario de edición en lugar de sólo un Modal
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Editar Movimiento"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Descripción'),
              ),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Monto'),
              ),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text('Ingreso'),
                      value: 'Ingreso',
                      groupValue: selectedType,
                      onChanged: (value) {
                        setState(() {
                          selectedType = value!;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text('Gasto'),
                      value: 'Gasto',
                      groupValue: selectedType,
                      onChanged: (value) {
                        setState(() {
                          selectedType = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                double amount = double.tryParse(amountController.text) ?? 0;

                // Verificar si el monto ingresado es válido
                if (amount == 0) {
                  Navigator.pop(context); // Salir si monto no es válido
                  return;
                }

                // Guardamos el monto original y el tipo para comparar luego si hubo cambios
                double originalAmount = movements[index]['amount'];
                String originalType = movements[index]['type'];

                // Verificar si hubo cambios en el monto o tipo
                if (amount != originalAmount || selectedType != originalType) {
                  setState(() {
                    // Si el tipo de movimiento es 'Gasto', lo convertimos en negativo
                    if (selectedType == 'Gasto') {
                      amount = -amount; // Aseguramos que el gasto sea negativo
                    }

                    // Restamos el valor del movimiento original antes de agregar el nuevo
                    saldo -= originalAmount;

                    // Modificamos el movimiento en la lista
                    movements[index] = {
                      'description': descriptionController.text,
                      'amount': amount,
                      'type': selectedType,
                      'date': DateTime.now(),
                    };

                    // Actualizamos el saldo con el nuevo valor
                    saldo += amount;
                  });
                }

                // Si no hay cambios, simplemente cerramos el diálogo sin hacer modificaciones
                Navigator.pop(context);
                descriptionController.clear();
                amountController.clear();
              },
              child: Text('Guardar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Cerrar el diálogo sin guardar cambios
              },
              child: Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  // Función para eliminar todo el historial con confirmación
  void deleteAllHistory() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar Eliminación'),
          content: Text('¿Estás seguro de que deseas eliminar todo el historial de movimientos?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                setState(() {
                  movements.clear(); // Limpiar lista de movimientos
                  saldo = 0; // Reiniciar el saldo
                });
                Navigator.of(context).pop(); // Cerrar el diálogo
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Historial de movimientos eliminado.')),
                );
              },
              child: Text('Sí'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: Text('No'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gestor Financiero',
          style: TextStyle(
            fontSize: 30, // Cambiar tamaño de la fuente
            color: Colors.blue, // Cambiar el color del texto
          ),
        ),
        centerTitle: true, // Esto centra el título en el AppBar
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Centra el saldo usando un widget Center
            Center(
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 500),
                child: Text(
                  'Saldo: S/. ${saldo.toStringAsFixed(2)}',
                  key: ValueKey<double>(saldo),
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                )
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'Descripción'),
            ),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Monto'),
            ),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('Ingreso'),
                    value: 'Ingreso',
                    groupValue: selectedType,
                    onChanged: (value) {
                      setState(() {
                        selectedType = value!;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('Gasto'),
                    value: 'Gasto',
                    groupValue: selectedType,
                    onChanged: (value) {
                      setState(() {
                        selectedType = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: addMovement, // Sin confirmación ahora
              child: Text('Agregar Movimiento'),
            ),
            // Indicador de carga mientras se agrega un movimiento
            if (_isLoading)
              Center(child: CircularProgressIndicator()),
            Expanded(
              child: ListView.builder(
                itemCount: movements.length,
                itemBuilder: (context, index) {
                  var movement = movements[index];
                  return Card(
                    color: movement['type'] == 'Ingreso'
                        ? Colors.green[100]
                        : Colors.red[100],
                    child: GestureDetector(
                      onLongPress: () {
                        // Mostrar un menú de opciones (editar o eliminar)
                        showModalBottomSheet(
                          context: context,
                          builder: (context) {
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: Icon(Icons.edit),
                                    title: Text('Editar'),
                                    onTap: () {
                                      // Llamar a la función de edición
                                      Navigator.pop(context);
                                      editMovement(index);
                                    },
                                  ),
                                  ListTile(
                                    leading: Icon(Icons.delete),
                                    title: Text('Eliminar'),
                                    onTap: () {
                                      // Llamar a la función de eliminación
                                      deleteMovement(index);
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      child: ListTile(
                        title: Text(movement['description']),
                        subtitle: Text(
                          'S/. ${movement['amount'].toStringAsFixed(2)} - ${movement['date'].toString()}',
                        ),
                        trailing: Icon(Icons.more_vert),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: addMovement, // Agrega el movimiento sin confirmación
            tooltip: 'Agregar Movimiento',
            child: Icon(Icons.add),
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: deleteAllHistory, // Elimina todo el historial con confirmación
            tooltip: 'Eliminar Todo',
            child: Icon(Icons.delete_forever),
          ),
        ],
      ),
    );
  }
}
