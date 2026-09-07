import 'package:flutter/material.dart';
import 'package:unisphere/core/constants/app_colors.dart';

/// Professional desktop enterprise data table for records, lists, and directories.
/// Features search bar, actions toolbar, column sorting, and pagination controls.
class AppDesktopDataTable extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final bool isLoading;
  final String searchHint;
  final ValueChanged<String>? onSearchChanged;
  final List<Widget>? actions;
  final int initialRowsPerPage;
  final List<int> availableRowsPerPage;
  final Widget? emptyWidget;

  const AppDesktopDataTable({
    super.key,
    required this.title,
    this.subtitle,
    required this.columns,
    required this.rows,
    this.isLoading = false,
    this.searchHint = 'Search records...',
    this.onSearchChanged,
    this.actions,
    this.initialRowsPerPage = 10,
    this.availableRowsPerPage = const [10, 25, 50],
    this.emptyWidget,
  });

  @override
  State<AppDesktopDataTable> createState() => _AppDesktopDataTableState();
}

class _AppDesktopDataTableState extends State<AppDesktopDataTable> {
  late int _rowsPerPage;
  int _currentPage = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _rowsPerPage = widget.initialRowsPerPage;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalRows = widget.rows.length;
    final totalPages = (totalRows / _rowsPerPage).ceil();
    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage > totalRows) ? totalRows : startIndex + _rowsPerPage;
    final paginatedRows = totalRows > 0 ? widget.rows.sublist(startIndex, endIndex) : <DataRow>[];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table Toolbar: Title + Search + Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$totalRows',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Search Input
                if (widget.onSearchChanged != null) ...[
                  SizedBox(
                    width: 220,
                    height: 36,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() => _currentPage = 0);
                        widget.onSearchChanged?.call(val);
                      },
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: widget.searchHint,
                        hintStyle: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                        prefixIcon: const Icon(Icons.search_rounded, size: 16, color: AppColors.textTertiary),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        filled: true,
                        fillColor: AppColors.backgroundSubtle,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.borderSubtle),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.borderSubtle),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                // Extra actions (Export, Filter, etc.)
                if (widget.actions != null) ...widget.actions!,
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.divider),

          // Main Table Area
          if (widget.isLoading)
            const Padding(
              padding: EdgeInsets.all(48.0),
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            )
          else if (widget.rows.isEmpty)
            widget.emptyWidget ??
                const Padding(
                  padding: EdgeInsets.all(48.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.inbox_outlined, size: 36, color: AppColors.textTertiary),
                        SizedBox(height: 8),
                        Text(
                          'No records found',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 800),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(AppColors.backgroundSubtle),
                  headingRowHeight: 44,
                  dataRowMinHeight: 52,
                  dataRowMaxHeight: 56,
                  dividerThickness: 1,
                  horizontalMargin: 20,
                  columnSpacing: 24,
                  columns: widget.columns,
                  rows: paginatedRows,
                ),
              ),
            ),

          const Divider(height: 1, color: AppColors.divider),

          // Pagination Footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Rows per page
                Row(
                  children: [
                    const Text('Rows per page:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(width: 8),
                    DropdownButton<int>(
                      value: _rowsPerPage,
                      isDense: true,
                      underline: const SizedBox.shrink(),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      items: widget.availableRowsPerPage.map((val) {
                        return DropdownMenuItem(value: val, child: Text('$val'));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _rowsPerPage = val;
                            _currentPage = 0;
                          });
                        }
                      },
                    ),
                  ],
                ),
                // Range info + Navigation buttons
                Row(
                  children: [
                    Text(
                      totalRows == 0
                          ? '0 of 0'
                          : 'Showing ${startIndex + 1}–$endIndex of $totalRows',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 14),
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 20),
                      onPressed: _currentPage > 0
                          ? () => setState(() => _currentPage--)
                          : null,
                      tooltip: 'Previous Page',
                      splashRadius: 18,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 20),
                      onPressed: _currentPage < totalPages - 1
                          ? () => setState(() => _currentPage++)
                          : null,
                      tooltip: 'Next Page',
                      splashRadius: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
