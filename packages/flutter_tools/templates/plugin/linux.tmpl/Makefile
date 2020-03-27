include plugin_configuration.mk

# Default build type.
BUILD=debug

# Plugins must be provided a populated flutter/ephemeral/ dir. Normally this
# would be the ephemeral directory of the application using the plugin.
ifeq ($(strip $(FLUTTER_EPHEMERAL_DIR)),)
$(error FLUTTER_EPHEMERAL_DIR must be provided)
endif

# Dependency locations
# Default to building in the plugin directory.
OUT_DIR=$(CURDIR)/../build/linux
# Sharing an OUT_DIR will be common, so use a subdirectory for intermediates.
PLUGIN_OUT_DIR=$(OUT_DIR)/$(PLUGIN_NAME)
OBJ_DIR=$(PLUGIN_OUT_DIR)/obj/$(BUILD)

# Flutter library
FLUTTER_LIB_NAME=flutter_linux_glfw
FLUTTER_LIB=$(FLUTTER_EPHEMERAL_DIR)/lib$(FLUTTER_LIB_NAME).so

# Add relevant code from the wrapper library, which is intended to be statically
# built into the plugin.
# Use abspath for the wrapper root, which can contain relative paths; the
# intermediate build files will be based on the source path, which will cause
# issues if they start with one or more '../'s.
WRAPPER_ROOT=$(abspath $(FLUTTER_EPHEMERAL_DIR)/cpp_client_wrapper_glfw)
# TODO: Once JSON codec files are merged, make a PLUGIN_CODEC variable in the
# top section. For now, using JSON codec would require changes here.
WRAPPER_SOURCES= \
	$(WRAPPER_ROOT)/engine_method_result.cc \
	$(WRAPPER_ROOT)/plugin_registrar.cc \
	$(WRAPPER_ROOT)/standard_codec.cc

# Use abspath for extra sources, which may also contain relative paths (see
# note above about WRAPPER_ROOT).
SOURCES=$(PLUGIN_NAME)_plugin.cc $(WRAPPER_SOURCES) $(abspath $(EXTRA_SOURCES))

WRAPPER_INCLUDE_DIR=$(WRAPPER_ROOT)/include
INCLUDE_DIRS=$(FLUTTER_EPHEMERAL_DIR) $(WRAPPER_INCLUDE_DIR)

# Build settings
CXX=clang++
CPPFLAGS.release=-DNDEBUG
CPPFLAGS.profile=$(CPPFLAGS.release)
CXXFLAGS.release=-O2
CXXFLAGS.profile=$(CXXFLAGS.release)
CXXFLAGS=-std=c++14 -Wall -Werror -fPIC -fvisibility=hidden \
	$(CXXFLAGS.$(BUILD)) $(EXTRA_CXXFLAGS)
CPPFLAGS=-DFLUTTER_PLUGIN_IMPL $(patsubst %,-I%,$(INCLUDE_DIRS)) \
	$(CPPFLAGS.$(BUILD)) $(EXTRA_CPPFLAGS)
LDFLAGS=-shared -L$(FLUTTER_EPHEMERAL_DIR) -l$(FLUTTER_LIB_NAME) $(EXTRA_LDFLAGS)

# Final output files that will be used by applications.
LIBRARY_OUT=$(OUT_DIR)/lib$(PLUGIN_NAME)_plugin.so

# Intermediate files.
OBJ_FILES=$(SOURCES:%.cc=$(OBJ_DIR)/%.o)
DEPENDENCY_FILES=$(OBJ_FILES:%.o=%.d)

# Targets

.PHONY: all
all: $(PLUGIN_NAME)

.PHONY: $(PLUGIN_NAME)
$(PLUGIN_NAME) : $(LIBRARY_OUT)

$(LIBRARY_OUT): $(OBJ_FILES)
	mkdir -p $(@D)
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) $^ $(LDFLAGS) -o $@

-include $(DEPENDENCY_FILES)

$(OBJ_DIR)/%.o : %.cc
	mkdir -p $(@D)
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) -MMD -c $< -o $@

.PHONY: clean
clean:
	rm -f $(LIBRARY_OUT)
	rm -rf $(PLUGINOUT_DIR)
