MXMLC = /opt/SDK/flex_sdk_3/bin/mxmlc

all :
	$(MXMLC) -o  bin/realtime.swf  -file-specs=src/realtime.as -allow-source-path-overlap=true
