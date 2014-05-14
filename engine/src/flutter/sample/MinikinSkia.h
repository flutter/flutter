namespace android {

class MinikinFontSkia : public MinikinFont {
public:
    explicit MinikinFontSkia(SkTypeface *typeface);

    ~MinikinFontSkia();

    bool GetGlyph(uint32_t codepoint, uint32_t *glyph) const;

    float GetHorizontalAdvance(uint32_t glyph_id,
        const MinikinPaint &paint) const;

    void GetBounds(MinikinRect* bounds, uint32_t glyph_id,
        const MinikinPaint& paint) const;

    // If buf is NULL, just update size
    bool GetTable(uint32_t tag, uint8_t *buf, size_t *size);

    int32_t GetUniqueId() const;

    SkTypeface *GetSkTypeface();

private:
    SkTypeface *mTypeface;

};

}  // namespace android