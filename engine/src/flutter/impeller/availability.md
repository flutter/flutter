# Impeller Availability

- **Note:** This assumes availability in stable releases. The Embedder API statuses are tricky.

| Releases | iOS | Android | Embedder API (Metal) | Embedder API (Vulkan) | Embedder API (OpenGL) | macOS | Windows | Linux | Web |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| **main** | Exclusive | Default | Preview | Experimental | Experimental | Default | Default | Default | Unavailable |
| **3.47** | Exclusive | Default | Preview | Experimental | Experimental | Default | Default | Default | Unavailable |
| **3.44** | Exclusive | Default | Preview | Experimental | Experimental | Preview | Experimental | Experimental | Unavailable |
| **3.41** | Exclusive | Default | Preview | Experimental | Experimental | Preview | Experimental | Experimental | Unavailable |
| **3.38** | Exclusive | Default | Preview | Experimental | Experimental | Preview | Experimental | Experimental | Unavailable |
| **3.35** | Exclusive | Default | Preview | Experimental | Experimental | Preview | Experimental | Experimental | Unavailable |
| **3.32** | Exclusive | Default | Preview | Experimental | Experimental | Preview | Experimental | Experimental | Unavailable |
| **3.29** | Exclusive | Default | Preview | Experimental | Experimental | Preview | Experimental | Experimental | Unavailable |
| **3.27** | Default | Default | Preview | Experimental | Experimental | Preview | Experimental | Experimental | Unavailable |
| **3.24** | Default | Preview | Preview | Experimental | Experimental | Preview | Experimental | Experimental | Unavailable |
| **3.22** | Default | Preview | Preview | Experimental | Experimental | Preview | Experimental | Experimental | Unavailable |
| **3.19** | Default | Preview | Preview | Experimental | Experimental | Preview | Experimental | Experimental | Unavailable |
| **3.16** | Default | Preview | Preview | Experimental | Experimental | Preview | Experimental | Experimental | Unavailable |
| **3.13** | Default | Unavailable | Preview | Experimental | Experimental | Preview | Experimental | Experimental | Unavailable |
| **3.10** | Default | Unavailable | Unavailable | Unavailable | Unavailable | Unavailable | Unavailable | Unavailable | Unavailable |
| **3.70** | Preview | Unavailable | Unavailable | Unavailable | Unavailable | Unavailable | Unavailable | Unavailable | Unavailable |
| **3.30** | Preview | Unavailable | Unavailable | Unavailable | Unavailable | Unavailable | Unavailable | Unavailable | Unavailable |
| **3.00** | Preview | Unavailable | Unavailable | Unavailable | Unavailable | Unavailable | Unavailable | Unavailable | Unavailable |
| **2.10** | Unavailable | Unavailable | Unavailable | Unavailable | Unavailable | Unavailable | Unavailable | Unavailable | Unavailable |

## Key
- **Exclusive** - Only Impeller is available.
- **Default** - Impeller is the default option, Skia is available.
- **Preview** - Can use Impeller with flags/manifest options. But, Skia is the default with no action.
- **Experimental** - Skia is the default. Impeller may or may not work. The team is not actively working on this and doesn't recommend using it.
- **Unavailable** - Only Skia is available.
