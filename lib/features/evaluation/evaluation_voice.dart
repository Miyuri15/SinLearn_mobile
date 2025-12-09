import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'learning_mode.dart';

class EvaluationVoicePage extends StatefulWidget {
	const EvaluationVoicePage({super.key});

	@override
	State<EvaluationVoicePage> createState() => _EvaluationVoicePageState();
}

class _EvaluationVoicePageState extends State<EvaluationVoicePage>
		with SingleTickerProviderStateMixin {
	int _modeIndex = 0; 
	bool _isRecording = true;
	late final AnimationController _pulse;

	@override
	void initState() {
		super.initState();
		_pulse = AnimationController(
			vsync: this,
			duration: const Duration(milliseconds: 1200),
		)..repeat(reverse: true);
	}

	@override
	void dispose() {
		_pulse.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		final theme = Theme.of(context);
		final isWide = MediaQuery.of(context).size.width >= 900;

		return Scaffold(
			backgroundColor: Colors.white, // ensure solid white
			appBar: isWide ? null : AppBar(toolbarHeight: 0),
			body: Stack(
				children: [
					Column(
						crossAxisAlignment: CrossAxisAlignment.stretch,
						children: [
							Padding(
								padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
								child: LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow = constraints.maxWidth < 420;
                    if (narrow) {
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        alignment: WrapAlignment.start,
                        children: [
                          _SegmentSwitch(
                            modeIndex: _modeIndex,
                            onChanged: (i) => setState(() => _modeIndex = i),
                          ),
                          OutlinedButton(onPressed: () {}, child: const Text('Syllabus')),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.add_circle_outline),
                            onSelected: (value) {
                              if (value == 'question') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Question Paper selected')),
                                );
                              } else if (value == 'rubric') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Rubric selected')),
                                );
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: 'question', child: Text('Question Paper')),
                              PopupMenuItem(value: 'rubric', child: Text('Rubric')),
                            ],
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        _SegmentSwitch(
                          modeIndex: _modeIndex,
                          onChanged: (i) => setState(() => _modeIndex = i),
                        ),
                        const Spacer(),
                        OutlinedButton(onPressed: () {}, child: const Text('Syllabus')),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.add_circle_outline),
                          onSelected: (value) {
                            if (value == 'question') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Question Paper selected')),
                              );
                            } else if (value == 'rubric') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Rubric selected')),
                              );
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'question', child: Text('Question Paper')),
                            PopupMenuItem(value: 'rubric', child: Text('Rubric')),
                          ],
                        ),
                      ],
                    );
                  },
                ),
							),
							const Divider(height: 1),
							Expanded(
								child: Center(
									child: Column(
										mainAxisSize: MainAxisSize.min,
										children: [
											Text('start_conversation'.tr(), style: theme.textTheme.titleMedium),
											const SizedBox(height: 8),
											Text('type_question'.tr(), style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
										],
									),
								),
							),
						],
					),
					_RecordingBar(
						isRecording: _isRecording,
						pulse: _pulse,
						onCancel: () => setState(() => _isRecording = false),
						onStop: () => setState(() => _isRecording = false),
					),
				],
			),
		);
	}
}

class _SegmentSwitch extends StatelessWidget {
	const _SegmentSwitch({required this.modeIndex, required this.onChanged});
	final int modeIndex;
	final ValueChanged<int> onChanged;

	@override
	Widget build(BuildContext context) {
		final theme = Theme.of(context);
		return Container(
			decoration: BoxDecoration(
				color: theme.colorScheme.surface,
				borderRadius: BorderRadius.circular(24),
				border: Border.all(color: theme.dividerColor),
			),
			child: Row(
				children: [
					_SegmentButton(
						selected: modeIndex == 0,
						label: 'Learning Mode',
						onTap: () {
							Navigator.of(context).pushReplacement(
								MaterialPageRoute(builder: (_) => const LearningModePage()),
							);
						},
					),
					_SegmentButton(
						selected: modeIndex == 1,
						label: 'Evaluation Mode',
						onTap: () => onChanged(1),
					),
				],
			),
		);
	}
}

class _SegmentButton extends StatelessWidget {
	const _SegmentButton({required this.selected, required this.label, required this.onTap});
	final bool selected;
	final String label;
	final VoidCallback onTap;

	@override
	Widget build(BuildContext context) {
		final theme = Theme.of(context);
		return InkWell(
			onTap: onTap,
			borderRadius: BorderRadius.circular(24),
			child: Container(
				padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
				decoration: BoxDecoration(
					color: selected ? theme.colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
					borderRadius: BorderRadius.circular(24),
				),
				child: Row(
					children: [
						Icon(selected ? Icons.menu_book : Icons.assignment_turned_in, size: 16, color: selected ? theme.colorScheme.primary : theme.iconTheme.color),
						const SizedBox(width: 6),
						Text(
							label,
							style: theme.textTheme.bodyMedium?.copyWith(
								color: selected ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color,
								fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
							),
						),
					],
				),
			),
		);
	}
}

class _RecordingBar extends StatelessWidget {
	const _RecordingBar({
		required this.isRecording,
		required this.pulse,
		required this.onCancel,
		required this.onStop,
	});
 
	final bool isRecording;
	final AnimationController pulse;
	final VoidCallback onCancel;
	final VoidCallback onStop;
 
	@override
	Widget build(BuildContext context) {
		if (!isRecording) return const SizedBox.shrink();
		final theme = Theme.of(context);
		return Align(
			alignment: Alignment.bottomCenter,
			child: SafeArea(
				top: false,
				child: Container(
					margin: const EdgeInsets.all(12),
					padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
					decoration: BoxDecoration(
						color: Colors.red.withOpacity(0.06),
						borderRadius: BorderRadius.circular(18),
						border: Border.all(color: Colors.red.withOpacity(0.12)),
					),
					child: Row(
						children: [
							const Icon(Icons.fiber_manual_record, color: Colors.red, size: 16),
							const SizedBox(width: 8),
							Text('recording'.tr(), style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red)),
							const SizedBox(width: 14),
							Expanded(child: _Waveform(pulse: pulse, color: Colors.red)), // larger waveform
							const SizedBox(width: 12),
							TextButton(onPressed: onCancel, child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodyMedium?.color))),
							const SizedBox(width: 6),
							TextButton(onPressed: onStop, child: const Text('Stop', style: TextStyle(color: Colors.red))),
						],
					),
				),
			),
		);
	}
}
 
 class _Waveform extends StatelessWidget {
   const _Waveform({required this.pulse, required this.color});
   final AnimationController pulse;
   final Color color;
 
   @override
   Widget build(BuildContext context) {
     return SizedBox(
       height: 36,
       child: AnimatedBuilder(
         animation: pulse,
         builder: (context, _) {
           const base = 6.0;
           final amp = 12.0 * pulse.value;
           final bars = [base + amp * 0.2, base + amp * 0.6, base + amp, base + amp * 0.6, base + amp * 0.2];
           return Row(
             mainAxisAlignment: MainAxisAlignment.center,
             mainAxisSize: MainAxisSize.max,
             children: bars
                 .map((h) => Padding(
                       padding: const EdgeInsets.symmetric(horizontal: 4),
                       child: Container(
                         width: 6,
                         height: h,
                         decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
                       ),
                     ))
                 .toList(),
           );
         },
       ),
     );
   }
 }

