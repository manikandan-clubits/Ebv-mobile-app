
import 'package:flutter/material.dart';


class CommonDataTable<T> extends StatefulWidget {
  final List<T> dataList;
  final List<DataColumn> columns;
  final DataTableSource Function(List<T>) dataSourceBuilder;
  final Function(T) onSelect;
  const CommonDataTable({
    required this.dataList,
    required this.columns,
    required this.dataSourceBuilder,
    required this.onSelect,
    super.key,
  });

  @override
  State<CommonDataTable<T>> createState() => _CommonDataTableState<T>();
}

class _CommonDataTableState<T> extends State<CommonDataTable<T>> {

  int? rowsPerPage = 10;

  @override
  Widget build(BuildContext context) {
    return DataTableTheme(
      data: DataTableThemeData(
        headingRowColor: MaterialStateProperty.all(Colors.white), // Header color
        dataRowColor: MaterialStateProperty.all(Colors.white),        // Rows color
        decoration: BoxDecoration(
          color: Colors.white,  // Table background color
        ),
      ),
      child: PaginatedDataTable(
        sortAscending: true,
        columns: widget.columns,
        source: widget.dataSourceBuilder(widget.dataList),
        rowsPerPage: rowsPerPage!,
        availableRowsPerPage: const [10, 20,50],
        onRowsPerPageChanged: (value) {
          setState(() {
            rowsPerPage=value;
          });
        },
        onPageChanged: (value) {},
        columnSpacing: 12,
        showCheckboxColumn: false,
        // showEmptyRows: false,
      ),
    );
  }
}


class GenericDataSource<T> extends DataTableSource {
  final List<T> _dataList;
  final List<DataCell> Function(T) buildCells;
  final Function(T) onSelect;

  GenericDataSource(this._dataList, this.buildCells,this.onSelect);

  @override
  DataRow getRow(int index) {
    if (index >= _dataList.length) return null!;
    final dataItem = _dataList[index];
    return DataRow.byIndex(
      color: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
          return index.isEven ? Colors.grey[200] : Colors.white; // Alternating colors
        },
      ),
      index: index, cells: buildCells(dataItem),
      onSelectChanged: (isSelected) {
        if (isSelected != null && isSelected) {
          onSelect(dataItem);  // Trigger the callback with the selected item
        }
      },);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _dataList.length;

  @override
  int get selectedRowCount => 0;
}
