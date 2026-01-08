import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';

class SipCalculatorScreen extends StatefulWidget {
  const SipCalculatorScreen({super.key});

  @override
  State<SipCalculatorScreen> createState() => _SipCalculatorScreenState();
}

class _SipCalculatorScreenState extends State<SipCalculatorScreen> {
  // Toggle State
  bool _isSip = true;

  // Input States
  double _investmentAmount = 5000;
  double _expectedReturn = 12;
  double _timePeriod = 10;
  
  // Advanced Options
  bool _showAdvanced = false;
  double _expenseRatio = 0;
  bool _adjustInflation = false;
  double _inflationRate = 6;
  double _taxRate = 0;

  // Results
  double _investedAmount = 0;
  double _estReturns = 0;
  double _totalValue = 0;
  
  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    double invested = 0;
    double total = 0;
    
    // Effective return rate after expense ratio
    double effectiveReturnRate = _expectedReturn - _expenseRatio;
    if (effectiveReturnRate < 0) effectiveReturnRate = 0;

    // Real return rate if adjusting for inflation
    // Real Return = (1 + Nominal) / (1 + Inflation) - 1
    if (_adjustInflation) {
      effectiveReturnRate = ((1 + effectiveReturnRate / 100) / (1 + _inflationRate / 100) - 1) * 100;
    }

    double r = effectiveReturnRate / 100;
    double n = _timePeriod;

    if (_isSip) {
      double i = r / 12; // Monthly rate
      double months = n * 12;
      invested = _investmentAmount * months;
      
      if (i == 0) {
        total = invested;
      } else {
        // Future Value of SIP: P * [((1+i)^n - 1) / i] * (1+i)
        // Usually SIP payments are made at the beginning of the period (Annuity Due)
        total = _investmentAmount * ((pow(1 + i, months) - 1) / i) * (1 + i);
      }
    } else {
      // Lumpsum
      invested = _investmentAmount;
      // Compound Interest: P * (1 + r)^n
      total = _investmentAmount * pow(1 + r, n);
    }
    
    // Apply Capital Gains Tax on Returns
    if (_taxRate > 0) {
      double gains = total - invested;
      if (gains > 0) {
        double tax = gains * (_taxRate / 100);
        total -= tax;
      }
    }

    setState(() {
      _investedAmount = invested;
      _totalValue = total;
      _estReturns = total - invested;
    });
  }

  void _updateMode(bool isSip) {
    if (_isSip == isSip) return;
    setState(() {
      _isSip = isSip;
      // Adjust defaults for UX
      if (!_isSip && _investmentAmount < 10000) _investmentAmount = 25000;
      if (_isSip && _investmentAmount > 20000) _investmentAmount = 5000;
      _calculate();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('SIP Calculator', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTypeToggle(),
            const SizedBox(height: 30),
            _buildGraph(),
            const SizedBox(height: 30),
            _buildSummaryCards(),
            const SizedBox(height: 30),
            _buildControls(),
            const SizedBox(height: 20),
            _buildAdvancedSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double width = constraints.maxWidth / 2;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                left: _isSip ? 0 : width,
                child: Container(
                  width: width,
                  height: 48,
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _updateMode(true),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style: TextStyle(
                            color: _isSip ? Colors.black : Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          child: const Text('SIP'),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _updateMode(false),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style: TextStyle(
                            color: !_isSip ? Colors.black : Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          child: const Text('Lumpsum'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGraph() {
    return AspectRatio(
      aspectRatio: 1.70,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _generateSpots(),
              isCurved: true,
              color: Colors.blue.shade600,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withOpacity(0.1),
              ),
            ),
             LineChartBarData(
              spots: _generateInvestedSpots(),
              isCurved: true,
              color: Colors.grey.shade300,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((LineBarSpot touchedSpot) {
                  return LineTooltipItem(
                    'Year ${touchedSpot.x.toInt()}\n${_formatCurrency(touchedSpot.y)}',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  List<FlSpot> _generateSpots() {
    List<FlSpot> spots = [];
    int yearSteps = _timePeriod.toInt();
    if (yearSteps == 0) return [const FlSpot(0, 0)];

    double effectiveReturnRate = _expectedReturn - _expenseRatio;
    if (_adjustInflation) {
      effectiveReturnRate = ((1 + effectiveReturnRate / 100) / (1 + _inflationRate / 100) - 1) * 100;
    }
    double r = effectiveReturnRate / 100;
    
    // Generate about 10-20 points for smoothness or just yearly
    int points = max(yearSteps, 10); 
    double stepSize = yearSteps / points;

    for (int i = 0; i <= points; i++) {
        double year = i * stepSize;
        double value;
        if (_isSip) {
            double monthlyRate = r / 12;
            double months = year * 12;
             if (monthlyRate == 0 || months == 0) {
                 value = _investmentAmount * months;
             } else {
                 value = _investmentAmount * ((pow(1 + monthlyRate, months) - 1) / monthlyRate) * (1 + monthlyRate);
             }
        } else {
            value = _investmentAmount * pow(1 + r, year);
        }
        
        // Tax Adjustment not applied to graph points for simplicity unless end of term, 
        // but let's just show raw growth for graph to be consistent with main formula
        spots.add(FlSpot(year, value));
    }
    return spots;
  }

  List<FlSpot> _generateInvestedSpots() {
     List<FlSpot> spots = [];
    int yearSteps = _timePeriod.toInt();
    int points = max(yearSteps, 10); 
    double stepSize = yearSteps / points;

     for (int i = 0; i <= points; i++) {
        double year = i * stepSize;
        double value;
        if (_isSip) {
          value = _investmentAmount * year * 12;
        } else {
          value = _investmentAmount;
        }
        spots.add(FlSpot(year, value));
     }
     return spots;
  }


  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(child: _buildResultTile('Invested', _investedAmount, Colors.grey.shade700)),
        const SizedBox(width: 12),
        Expanded(child: _buildResultTile('Returns', _estReturns, Colors.green.shade600)),
        const SizedBox(width: 12),
        Expanded(child: _buildResultTile('Total', _totalValue, Colors.blue.shade700, isBold: true)),
      ],
    );
  }

  Widget _buildResultTile(String label, double value, Color color, {bool isBold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          CountUpText(
            value: value,
            formatter: _formatCompactCurrency,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Column(
      children: [
        _buildSliderParams(
          title: _isSip ? 'Monthly Investment' : 'Total Investment',
          value: _investmentAmount,
          min: _isSip ? 500 : 1000,
          max: _isSip ? 100000 : 10000000,
          isCurrency: true,
          step: _isSip ? 500 : 5000,
          onChanged: (val) {
             setState(() {
               _investmentAmount = val;
               _calculate();
             });
          },
        ),
        const SizedBox(height: 24),
        _buildSliderParams(
          title: 'Expected Return',
          value: _expectedReturn,
          min: 1,
          max: 100,
          suffix: '%',
          onChanged: (val) {
             setState(() {
               _expectedReturn = val;
               _calculate();
             });
          },
        ),
        const SizedBox(height: 24),
        _buildSliderParams(
          title: 'Time Period',
          value: _timePeriod,
          min: 1,
          max: 50,
          suffix: ' Yr',
          isInteger: true,
          onChanged: (val) {
             setState(() {
               _timePeriod = val;
               _calculate();
             });
          },
        ),
      ],
    );
  }

  Widget _buildSliderParams({
    required String title,
    required double value,
    required double min,
    required double max,
    required Function(double) onChanged,
    String? suffix,
    bool isCurrency = false,
    bool isInteger = false,
    double? step,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                title,
                key: ValueKey(title),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isCurrency 
                  ? _formatCurrency(value)
                  : '${isInteger ? value.toInt() : value.toStringAsFixed(1)}${suffix ?? ''}',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            activeTrackColor: Colors.blue.shade600,
            inactiveTrackColor: Colors.blue.shade100,
            thumbColor: Colors.white,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10, elevation: 4),
            overlayColor: Colors.blue.withOpacity(0.2),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: step != null ? ((max - min) / step).round() : (max.toInt() - min.toInt()),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
  
  Widget _buildAdvancedSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _showAdvanced = !_showAdvanced;
            });
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Advanced Options',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(
                _showAdvanced ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: Colors.grey.shade600,
              ),
            ],
          ),
        ),
        if (_showAdvanced) ...[
          const SizedBox(height: 20),
          _buildSliderParams(
            title: 'Expense Ratio',
            value: _expenseRatio,
            min: 0,
            max: 3,
            suffix: '%',
            step: 0.1,
            onChanged: (val) {
               setState(() {
                 _expenseRatio = val;
                 _calculate();
               });
            },
          ),
          const SizedBox(height: 16),
          _buildSliderParams(
             title: 'Tax Rate',
             value: _taxRate,
             min: 0,
             max: 50,
             suffix: '%',
             step: 1,
             onChanged: (val) {
                setState(() {
                  _taxRate = val;
                  _calculate();
                });
             },
           ),
           const SizedBox(height: 16),
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               const Text('Adjust for Inflation', style: TextStyle(fontWeight: FontWeight.w500)),
               Switch.adaptive(
                 value: _adjustInflation,
                 onChanged: (val) {
                   setState(() {
                     _adjustInflation = val;
                     _calculate();
                   });
                 }
               )
             ],
           ),
           if (_adjustInflation) ...[
             const SizedBox(height: 16),
             _buildSliderParams(
                title: 'Inflation Rate',
                value: _inflationRate,
                min: 0,
                max: 20,
                suffix: '%',
                step: 0.5,
                onChanged: (val) {
                   setState(() {
                     _inflationRate = val;
                     _calculate();
                   });
                },
              ),
           ]
        ]
      ],
    );
  }

  String _formatCurrency(double value) {
    if (value >= 10000000) {
      return '₹${(value / 10000000).toStringAsFixed(2)} Cr';
    } else if (value >= 100000) {
      return '₹${(value / 100000).toStringAsFixed(2)} L';
    }
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(value);
  }

  String _formatCompactCurrency(double value) {
    if (value >= 10000000) {
      return '${(value / 10000000).toStringAsFixed(2)}Cr';
    } else if (value >= 100000) {
      return '${(value / 100000).toStringAsFixed(2)}L';
    }
    return NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹').format(value);
  }
}

class CountUpText extends StatefulWidget {
  final double value;
  final String Function(double) formatter;
  final TextStyle style;
  final Duration duration;

  const CountUpText({
    super.key,
    required this.value,
    required this.formatter,
    this.style = const TextStyle(),
    this.duration = const Duration(milliseconds: 700),
  });

  @override
  State<CountUpText> createState() => _CountUpTextState();
}

class _CountUpTextState extends State<CountUpText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _oldValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
    _oldValue = widget.value;
  }

  @override
  void didUpdateWidget(CountUpText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(begin: _oldValue, end: widget.value).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.reset();
      _controller.forward();
      _oldValue = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          widget.formatter(_animation.value),
          style: widget.style,
        );
      },
    );
  }
}
