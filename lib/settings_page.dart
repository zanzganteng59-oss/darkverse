import 'package:flutter/material.dart';
import 'package:darkverse/theme/app_theme.dart';
import 'services/lang.dart';
import 'services/font_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedLang = Lang.current;
  String _selectedFont = TextStyleService.fontFamily;
  double _fontSize = TextStyleService.fontSize;
  FontWeight _fontWeight = TextStyleService.fontWeight;
  Color _textColor = TextStyleService.textColor;

  @override
  void initState() {
    super.initState();
    Lang.init().then((_) => setState(() => _selectedLang = Lang.current));
    TextStyleService.init().then((_) {
      setState(() {
        _selectedFont = TextStyleService.fontFamily;
        _fontSize = TextStyleService.fontSize;
        _fontWeight = TextStyleService.fontWeight;
        _textColor = TextStyleService.textColor;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgCard,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: AppTheme.cardDecor().copyWith(
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(Lang.t('settings').toUpperCase(), style: AppTheme.headingM.copyWith(letterSpacing: 2)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Lang.t('language')),
            const SizedBox(height: 12),
            _buildLanguageGrid(),
            const SizedBox(height: 24),
            _buildSectionHeader(Lang.t('font')),
            const SizedBox(height: 12),
            _buildFontGrid(),
            const SizedBox(height: 24),
            _buildSectionHeader(Lang.t('font_size')),
            const SizedBox(height: 12),
            _buildFontSizeSlider(),
            const SizedBox(height: 24),
            _buildSectionHeader(Lang.t('font_weight')),
            const SizedBox(height: 12),
            _buildFontWeightSlider(),
            const SizedBox(height: 24),
            _buildSectionHeader(Lang.t('text_color')),
            const SizedBox(height: 12),
            _buildColorGrid(),
            const SizedBox(height: 24),
            _buildPreview(),
            const SizedBox(height: 24),
            _buildActionButtons(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 3, height: 14, decoration: BoxDecoration(color: AppTheme.coral, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(title.toUpperCase(), style: AppTheme.label.copyWith(color: AppTheme.textMuted, letterSpacing: 3)),
      ],
    );
  }

  Widget _buildLanguageGrid() {
    final languages = Lang.supportedLanguages;
    return Container(
      decoration: AppTheme.cardDecor(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.borderSubtle))),
            child: Row(
              children: [
                const Icon(Icons.language, color: AppTheme.sky, size: 18),
                const SizedBox(width: 8),
                Text("${languages.length} ${Lang.t('language')}", style: AppTheme.bodyM),
              ],
            ),
          ),
          Container(
            height: 240,
            padding: const EdgeInsets.all(8),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 2.8,
              ),
              itemCount: languages.length,
              itemBuilder: (context, i) {
                final lang = languages[i];
                final isSelected = lang.key == _selectedLang;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedLang = lang.key);
                    Lang.setLanguage(lang.key);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.sky.withValues(alpha: 0.2) : AppTheme.bgInput,
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      border: Border.all(color: isSelected ? AppTheme.sky : AppTheme.borderSubtle, width: isSelected ? 2 : 1),
                    ),
                    child: Center(
                      child: Text(
                        lang.value,
                        style: TextStyle(
                          color: isSelected ? AppTheme.sky : AppTheme.textSecondary,
                          fontSize: 9,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFontGrid() {
    return Container(
      height: 200,
      decoration: AppTheme.cardDecor(),
      padding: const EdgeInsets.all(8),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 3.5,
        ),
        itemCount: TextStyleService.fontOptions.length,
        itemBuilder: (context, i) {
          final font = TextStyleService.fontOptions[i];
          final isSelected = font['family'] == _selectedFont;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedFont = font['family']);
              TextStyleService.setFontFamily(font['family']);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.coral.withValues(alpha: 0.15) : AppTheme.bgInput,
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                border: Border.all(color: isSelected ? AppTheme.coral : AppTheme.borderSubtle, width: isSelected ? 2 : 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    font['name'],
                    style: TextStyle(
                      fontFamily: font['family'].isEmpty ? null : font['family'],
                      color: isSelected ? AppTheme.coral : AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    font['style'],
                    style: AppTheme.caption,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFontSizeSlider() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecor(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("A", style: AppTheme.bodyM),
              Text("${_fontSize.round()}px", style: AppTheme.bodyL.copyWith(color: AppTheme.coral, fontWeight: FontWeight.w700)),
              const Text("A", style: TextStyle(color: AppTheme.textSecondary, fontSize: 24)),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppTheme.coral,
              inactiveTrackColor: AppTheme.borderSubtle,
              thumbColor: AppTheme.coral,
              overlayColor: AppTheme.coral.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: _fontSize,
              min: 8,
              max: 32,
              divisions: 24,
              onChanged: (v) {
                setState(() => _fontSize = v);
                TextStyleService.setFontSize(v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFontWeightSlider() {
    final weightNames = ['Thin', 'ExtraLight', 'Light', 'Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold', 'Black'];
    final weightIndex = TextStyleService.fontWeights.indexOf(_fontWeight);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecor(),
      child: Column(
        children: [
          Text(
            weightNames[weightIndex.clamp(0, weightNames.length - 1)],
            style: AppTheme.bodyL.copyWith(color: AppTheme.coral, fontWeight: _fontWeight),
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppTheme.coral,
              inactiveTrackColor: AppTheme.borderSubtle,
              thumbColor: AppTheme.coral,
              overlayColor: AppTheme.coral.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: weightIndex.toDouble(),
              min: 0,
              max: 8,
              divisions: 8,
              onChanged: (v) {
                final w = TextStyleService.fontWeights[v.round()];
                setState(() => _fontWeight = w);
                TextStyleService.setFontWeight(w);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorGrid() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.cardDecor(),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: TextStyleService.colorPresets.map((preset) {
          final c = preset['color'] as Color;
          final isSelected = c.value == _textColor.value;
          return GestureDetector(
            onTap: () {
              setState(() => _textColor = c);
              TextStyleService.setTextColor(c);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? AppTheme.textPrimary : AppTheme.borderSubtle, width: isSelected ? 3 : 1),
                boxShadow: isSelected ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 12)] : null,
              ),
              child: isSelected ? const Icon(Icons.check, color: AppTheme.textPrimary, size: 18) : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Lang.t('preview').toUpperCase(), style: AppTheme.label.copyWith(color: AppTheme.textMuted, letterSpacing: 2)),
          const SizedBox(height: 16),
          Text(
            Lang.t('public_chat'),
            style: TextStyle(
              fontFamily: _selectedFont.isEmpty ? null : _selectedFont,
              fontSize: _fontSize + 4,
              fontWeight: FontWeight.w900,
              color: _textColor,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Hello! ${Lang.t('type_message')}",
            style: TextStyle(
              fontFamily: _selectedFont.isEmpty ? null : _selectedFont,
              fontSize: _fontSize,
              fontWeight: _fontWeight,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "INI TEST FONT: 0123456789 !@#\$%^&*()",
            style: TextStyle(
              fontFamily: _selectedFont.isEmpty ? null : _selectedFont,
              fontSize: _fontSize - 2,
              fontWeight: _fontWeight,
              color: _textColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              TextStyleService.reset();
              setState(() {
                _selectedFont = 'Orbitron';
                _fontSize = 14.0;
                _fontWeight = FontWeight.w400;
                _textColor = Colors.white;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: AppTheme.inputDecor(),
              child: Center(
                child: Text(Lang.t('reset'), style: AppTheme.bodyL.copyWith(fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("${Lang.t('success')}!"), backgroundColor: AppTheme.mint),
              );
              Navigator.pop(context);
            },
            style: AppTheme.primaryButton(AppTheme.coral),
            child: Text(Lang.t('apply')),
          ),
        ),
      ],
    );
  }
}
