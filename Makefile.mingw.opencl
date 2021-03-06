###########################################################################
#   Copyright (C) 2011 by Oliver Bock                                     #
#   oliver.bock[AT]aei.mpg.de                                             #
#                                                                         #
#   This file is part of Einstein@Home (Radio Pulsar Edition).            #
#                                                                         #
#   Einstein@Home is free software: you can redistribute it and/or modify #
#   it under the terms of the GNU General Public License as published     #
#   by the Free Software Foundation, version 2 of the License.            #
#                                                                         #
#   Einstein@Home is distributed in the hope that it will be useful,      #
#   but WITHOUT ANY WARRANTY; without even the implied warranty of        #
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the          #
#   GNU General Public License for more details.                          #
#                                                                         #
#   You should have received a copy of the GNU General Public License     #
#   along with Einstein@Home. If not, see <http://www.gnu.org/licenses/>. #
#                                                                         #
###########################################################################

# path settings
EINSTEIN_RADIO_SRC?=$(PWD)
EINSTEIN_RADIO_INSTALL?=$(PWD)
NVIDIA_SDK_INSTALL_PATH ?= /usr/local/cuda
AMDAPPSDKROOT ?= /opt/AMDAPP

# config values
CXX ?= g++
ARCH=$(if $(findstring x86_64-w64-mingw32-g++,$(CXX)),64,32)

# variables
LIBS = -Wl,-Bstatic
LIBS += -L$(EINSTEIN_RADIO_INSTALL)/lib
LIBS += $(shell $(EINSTEIN_RADIO_INSTALL)/bin/gsl-config --libs)
LIBS += -lfftw3f -lm # there's no pkg-config in our MinGW setup
LIBS += $(shell $(EINSTEIN_RADIO_INSTALL)/bin/xml2-config --libs)
LIBS += -lws2_32 # required by libxml2
LIBS += -lclfft
LIBS += -lboinc_opencl -lboinc_graphics2 -lboinc_api -lboinc
LIBS += -lpsapi # required by BOINC API
LIBS += -lbfd -liberty -lintl # required for exception handling
LIBS += -Wl,-Bdynamic
LIBS += -lOpenCL -L$(EINSTEIN_RADIO_SRC)/opencl/redist/win$(ARCH)/2.6/lib  # OpenCL runtime
LIBS += $(EINSTEIN_RADIO_INSTALL)/lib/libz.a

LDFLAGS = -static-libgcc $(if $(ARCH)=64,-static-libstdc++,)

CXXFLAGS += -I$(EINSTEIN_RADIO_INSTALL)/include
CXXFLAGS += $(shell $(EINSTEIN_RADIO_INSTALL)/bin/gsl-config --cflags)
CXXFLAGS += $(shell $(EINSTEIN_RADIO_INSTALL)/bin/xml2-config --cflags)
CXXFLAGS += -I$(EINSTEIN_RADIO_INSTALL)/include/boinc
CXXFLAGS += -I$(NVIDIA_SDK_INSTALL_PATH)/cuda/include -I$(AMDAPPSDKROOT)/include -I../include
CXXFLAGS += -DHAVE_INLINE -DBOINCIFIED $(CPPFLAGS)
CXXFLAGS += -malign-double
CXXFLAGS += -DUSE_OPENCL

DEPS = Makefile
OBJS = demod_binary.o demod_binary_ocl.o ocl_utilities.o hs_common.o rngmed.o erp_boinc_ipc.o erp_getopt.o erp_getopt1.o erp_utilities.o exchndl.o
EINSTEINBINARY_TARGET ?= einsteinbinary_opencl.exe
TARGET = $(EINSTEINBINARY_TARGET)

# primary role based tagets
default: release
debug: $(TARGET)
#profile: clean $(TARGET)
release: clean $(TARGET)

# target specific options (generic)
debug: CXXFLAGS_BASE += -DLOGLEVEL=debug -pg -O0 -Wall
#profile: CXXFLAGS_BASE += -DNDEBUG -DLOGLEVEL=info -O3 -Wall
release: CXXFLAGS_BASE += -DNDEBUG -DLOGLEVEL=info -O3 -Wall

# target specific options (gcc)
debug: CXXFLAGS_GCC += $(CXXFLAGS) $(CXXFLAGS_BASE) -gstabs3
#profile: CXXFLAGS_GCC += $(CXXFLAGS) $(CXXFLAGS_BASE) -gstabs3 -fprofile-generate
#release: CXXFLAGS_GCC += $(CXXFLAGS) $(CXXFLAGS_BASE) -gstabs3 -fprofile-use
release: CXXFLAGS_GCC += $(CXXFLAGS) $(CXXFLAGS_BASE) -gstabs3

# file based targets
#profile:
#	@echo "Removing previous profiling data..."
#	rm -f *_profile.*
#	rm -f *.gcda
#	@echo "In order to gather profiling data one needs to run the following command on a windoze box:"
#	@echo "cd build/einsteinradio && $(TARGET) -t $(EINSTEIN_RADIO_SRC)/../test/templates_400Hz_2_short.bank -l $(EINSTEIN_RADIO_SRC)/data/zaplist_232.txt -A 0.04 -P 4.0 -W -z -i $(EINSTEIN_RADIO_SRC)/../test/J1907+0740_dm_482.bina$

$(TARGET): $(DEPS) $(EINSTEIN_RADIO_SRC)/erp_boinc_wrapper.cpp $(OBJS)
	$(CXX) -g $(CXXFLAGS_GCC) $(LDFLAGS) $(EINSTEIN_RADIO_SRC)/erp_boinc_wrapper.cpp -o $(TARGET) $(OBJS) $(LIBS)

demod_binary.o: $(DEPS) $(EINSTEIN_RADIO_SRC)/demod_binary.c $(EINSTEIN_RADIO_SRC)/demod_binary.h
	$(CXX) -g $(CXXFLAGS_GCC) -c $(EINSTEIN_RADIO_SRC)/demod_binary.c

demod_binary_ocl.o: $(DEPS) $(EINSTEIN_RADIO_SRC)/opencl/app/demod_binary_ocl.cpp $(EINSTEIN_RADIO_SRC)/opencl/app/demod_binary_ocl.h $(EINSTEIN_RADIO_SRC)/opencl/app/demod_binary_ocl_kernels.h
	$(CXX) -g $(CXXFLAGS_GCC) -c $(EINSTEIN_RADIO_SRC)/opencl/app/demod_binary_ocl.cpp

ocl_utilities.o: $(DEPS) $(EINSTEIN_RADIO_SRC)/opencl/app/ocl_utilities.cpp $(EINSTEIN_RADIO_SRC)/opencl/app/ocl_utilities.h
	$(CXX) -g $(CXXFLAGS_GCC) -c $(EINSTEIN_RADIO_SRC)/opencl/app/ocl_utilities.cpp

hs_common.o: $(DEPS) $(EINSTEIN_RADIO_SRC)/hs_common.c $(EINSTEIN_RADIO_SRC)/hs_common.h
	$(CXX) -g $(CXXFLAGS_GCC) -c $(EINSTEIN_RADIO_SRC)/hs_common.c

rngmed.o: $(DEPS) $(EINSTEIN_RADIO_SRC)/rngmed.c $(EINSTEIN_RADIO_SRC)/rngmed.h
	$(CXX) -g $(CXXFLAGS_GCC) -c $(EINSTEIN_RADIO_SRC)/rngmed.c

erp_boinc_ipc.o: $(DEPS) $(EINSTEIN_RADIO_SRC)/erp_boinc_ipc.cpp $(EINSTEIN_RADIO_SRC)/erp_boinc_ipc.h
	$(CXX) -g $(CXXFLAGS_GCC) -c $(EINSTEIN_RADIO_SRC)/erp_boinc_ipc.cpp

erp_getopt.o: $(DEPS) $(EINSTEIN_RADIO_SRC)/erp_getopt.c $(EINSTEIN_RADIO_SRC)/erp_getopt.h $(EINSTEIN_RADIO_SRC)/erp_getopt_int.h
	$(CXX) -g $(CXXFLAGS_GCC) -c $(EINSTEIN_RADIO_SRC)/erp_getopt.c

erp_getopt1.o: $(DEPS) $(EINSTEIN_RADIO_SRC)/erp_getopt1.c $(EINSTEIN_RADIO_SRC)/erp_getopt.h $(EINSTEIN_RADIO_SRC)/erp_getopt_int.h
	$(CXX) -g $(CXXFLAGS_GCC) -c $(EINSTEIN_RADIO_SRC)/erp_getopt1.c

erp_utilities.o: $(DEPS) $(EINSTEIN_RADIO_SRC)/erp_utilities.cpp $(EINSTEIN_RADIO_SRC)/erp_utilities.h
	$(CXX) -g $(CXXFLAGS_GCC) -c $(EINSTEIN_RADIO_SRC)/erp_utilities.cpp

exchndl.o: $(DEPS) $(EINSTEIN_RADIO_SRC)/exchndl$(ARCH).c
	$(CXX) -g $(CXXFLAGS_GCC) -c $(EINSTEIN_RADIO_SRC)/exchndl$(ARCH).c -o exchndl.o

install:
	mkdir -p $(EINSTEIN_RADIO_INSTALL)/../dist
	cp $(TARGET) $(EINSTEIN_RADIO_INSTALL)/../dist

clean:
	rm -f $(OBJS) $(TARGET)
