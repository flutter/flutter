#ifndef GraphicsContextCullSaver_h
#define GraphicsContextCullSaver_h

#include "platform/graphics/GraphicsContext.h"

namespace blink {

class FloatRect;

class GraphicsContextCullSaver {
    WTF_MAKE_FAST_ALLOCATED;
public:
    GraphicsContextCullSaver(GraphicsContext& context)
        : m_context(context)
        , m_cullApplied(false)
    {
    }

    GraphicsContextCullSaver(GraphicsContext& context, const FloatRect& rect)
        : m_context(context)
        , m_cullApplied(true)
    {
        context.beginCull(rect);
    }

    ~GraphicsContextCullSaver()
    {
        if (m_cullApplied)
            m_context.endCull();
    }

    void cull(const FloatRect& rect)
    {
        ASSERT(!m_cullApplied);
        m_context.beginCull(rect);
        m_cullApplied = true;
    }

private:
    GraphicsContext& m_context;
    bool m_cullApplied;
};

} // namespace blink

#endif // GraphicsContextCullSaver_h
