namespace android {

class MinikinFontSkia : public MinikinFont {
public:
    explicit MinikinFontSkia(SkTypeface *typeface);

    ~MinikinFontSkia();

    float GetHorizontalAdvance(uint32_t glyph_id,
        const MinikinPaint &paint) const;

    void GetBounds(MinikinRect* bounds, uint32_t glyph_id,
        const MinikinPaint& paint) const;

    const void* GetTable(uint32_t tag, size_t* size, MinikinDestroyFunc* destroy);

    SkTypeface *GetSkTypeface();

private:
    SkTypeface *mTypeface;

};

}  // namespace android
