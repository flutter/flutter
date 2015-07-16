Linkability
===========

This file has ideas only, so far. Comments welcome.

Scenarios
---------

* soduku app:
   * want to share the board layout, but not my progress so far
   * want to transfer my progress to another device
* a wikipedia-like app:
   * follow links to other topics
   * have links from other apps (e.g. search) to a specific subsection of a topic
* an instant-messenger app:
   * bookmark specific group conversations
* a social network app:
   * link to specific posts
   * link to social network constructs like user lists (twitter), communities (g+), walls (fb), users…
* an IDE
   * want to save a particular state of open windows, maybe to share with other developers
* Navigation app
   * want to link to different modes of the app: nav mode, search page, personal profile, settings, etc
   * want to link to specific points of interest, either public (restaurant) or private (home, work, saved locations)
   * want to link to a specific map location, zoom level, direction, angle, time of day (for shadows), route (for navigation)
   * want to link to a destination in nav mode (without a route)
* Podcast app
   * want to link to a specific view (e.g. in doggcatcher, feeds, audio, video, news...)
   * want to link to a specific podcast (maybe independently of the app)
   * want to link to a specific time in a specific episode of a specific podcast
   * save ui state (e.g. size of ui area vs podcast list in doggcatcher, scroll position in a list, specific settings window being on top of specific tab at a specific scroll position, etc)
* News app
   * categories
   * articles
   * sets of categories
   * sets of categories + a selected category + a scroll position
   * app sections (e.g. Newsstand’s Explore vs Read Now vs My Library)
   * specific settings in the settings section of the app
* Code Review Tools
   * a specific code review
   * a specific file in a specific code review
   * code review plus scroll position
   * specific comment
   * the state of the UI, such as which changes are visible, which comments are expanded, sort settings, filter settings, etc; whether the settings window is open, what tab it’s open to, what field is focused…

UI
--

* Sharing current state to another device using NFC: just put the phones together, the active app(s?) serialise their state to a “URL” and that is sent to the other device
* App exposes a “permalink” or “get link” UI that exposes a string you can Share (a la Android’s Share intent) or copy and paste.
* An accessibility tree should expose the URL of each part of the app so that a user with an accessibility tool can bookmark a particular location in the app to jump to it later.

Thoughts
--------

* Seems like you link to three kinds of things:
   * different in-app concepts, which might be shared across apps
      * specific posts in a social network
      * users
      * particular game board starting configurations, game levels
      * wikipedia topics
      * search results
      * POIs in a map
      * videos on Vimeo, YouTube, etc
      * a code review / CL / pull request
      * a comment on a code review
      * a file in a code review
      * a comment in a blog post
      * telephone numbers
      * lat/long coordinates
      * podcasts
   * different top-level parts of the app (shallow state)
      * e.g. in Facebook, linking to the stream; in G+, linking to the communities landing page, etc
      * in a maps app, the mode (satellite, navigation, etc)
   * deep state
      * the current state of a particular game board, e.g. all the piece positions in chess, all the current choices in soduku...
      * what windows are open, what field is focused, what widgets are expanded, the precise view of a 3D map, etc
      * subsection of a topic in wikipedia (scroll position)
* Since almost every app is going to have app-specific items, we need to make the item space trivially extensible (no registry, no fixed vocabulary). This means that common items (e.g. lat/long coordinates, podcasts) will probably evolve conventions organically within communities rather than in a centralised fashion
* We don’t have to use URLs as they are known today, but doing so would leverage the existing infrastructure which might be valuable

Ideas
-----

* Two kinds of URLs: application state, and “things”.
* Application state URLs consist of an identifier for the app, plus a blob of data for how to open the app
* Thing URLs identify a thing, either by string name, opaque identifier, or more structured data (e.g. two comma-separated floating point numbers for lat/long).
* Thing URLs have a label saying what they are, e.g. “poi” or “geo” or “cl-comment” or something.
* Maybe “apps” are just things, and going to an app is like picking that app thing from the system app, the same way you’d pick a post from a social network app.
