import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../network/places_datasource.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_text_field.dart';

class PlaceAutocompleteField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;
  final void Function(PlaceDetails details) onPlaceSelected;

  const PlaceAutocompleteField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
    required this.onPlaceSelected,
  });

  @override
  ConsumerState<PlaceAutocompleteField> createState() =>
      _PlaceAutocompleteFieldState();
}

class _PlaceAutocompleteFieldState
    extends ConsumerState<PlaceAutocompleteField> {
  final PlacesDatasource _datasource = PlacesDatasource();
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();

  OverlayEntry? _overlay;
  List<PlaceSuggestion> _suggestions = [];
  Timer? _debounce;
  bool _loading = false;
  bool _justSelected = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _debounce?.cancel();
      _removeOverlay();
    }
  }

  void _onTextChanged() {
    _debounce?.cancel();
    if (_justSelected) {
      _justSelected = false;
      _removeOverlay();
      return;
    }
    final text = widget.controller.text;
    if (text.trim().length < 3) {
      _removeOverlay();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _fetch(text));
  }

  Future<void> _fetch(String input) async {
    if (!mounted) return;
    setState(() => _loading = true);
    final lang = ref.read(localeProvider).languageCode;
    final results = await _datasource.autocomplete(input, language: lang);
    if (!mounted) return;
    setState(() {
      _suggestions = results;
      _loading = false;
    });
    if (results.isEmpty) {
      _removeOverlay();
      return;
    }
    if (_focusNode.hasFocus) {
      _showOverlay();
    }
  }

  Future<void> _selectSuggestion(PlaceSuggestion suggestion) async {
    _removeOverlay();
    _debounce?.cancel();
    _focusNode.unfocus();
    final lang = ref.read(localeProvider).languageCode;
    final details =
        await _datasource.details(suggestion.placeId, language: lang);
    final finalText = details?.formattedAddress ?? suggestion.mainText;
    _justSelected = true;
    widget.controller.text = finalText;
    widget.controller.selection = TextSelection.collapsed(
      offset: widget.controller.text.length,
    );
    if (details != null) {
      widget.onPlaceSelected(details);
    }
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  void _showOverlay() {
    _removeOverlay();
    final overlay = Overlay.of(context);
    final box = context.findRenderObject() as RenderBox?;
    final width = box?.size.width ?? MediaQuery.sizeOf(context).width - 48;
    final height = box?.size.height ?? 80;
    debugPrint('[places] showOverlay: width=$width height=$height');
    _overlay = OverlayEntry(
      builder: (ctx) => CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        offset: Offset(0, height + 6),
        child: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: width,
            child: _SuggestionDropdown(
              suggestions: _suggestions,
              onTap: _selectSuggestion,
            ),
          ),
        ),
      ),
    );
    overlay.insert(_overlay!);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: AppTextField(
        controller: widget.controller,
        focusNode: _focusNode,
        label: widget.label,
        hint: widget.hint,
        prefixIcon: Icons.location_on_outlined,
        keyboardType: TextInputType.streetAddress,
        validator: widget.validator,
        suffixIcon: _loading
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

class _SuggestionDropdown extends StatelessWidget {
  final List<PlaceSuggestion> suggestions;
  final void Function(PlaceSuggestion) onTap;

  const _SuggestionDropdown({
    required this.suggestions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 240),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          itemCount: suggestions.length,
          separatorBuilder: (context, index) => const Divider(
            height: 1,
            color: AppColors.divider,
            indent: AppSpacing.md,
            endIndent: AppSpacing.md,
          ),
          itemBuilder: (ctx, i) {
            final s = suggestions[i];
            return _SuggestionTile(suggestion: s, onTap: () => onTap(s));
          },
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatefulWidget {
  final PlaceSuggestion suggestion;
  final VoidCallback onTap;

  const _SuggestionTile({required this.suggestion, required this.onTap});

  @override
  State<_SuggestionTile> createState() => _SuggestionTileState();
}

class _SuggestionTileState extends State<_SuggestionTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: _hovered
              ? AppColors.secondary.withValues(alpha: 0.07)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.place_outlined,
                size: 16,
                color: AppColors.secondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.suggestion.mainText,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.suggestion.secondaryText.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.suggestion.secondaryText,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
