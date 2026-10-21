FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      python3-pip python3-venv xvfb x11vnc novnc websockify fluxbox \
      libgl1 libglu1-mesa libgl1-mesa-dri libxft2 libxcursor1 libxrandr2 libxi6 \
      libfontconfig1 libglib2.0-0 libatomic1 ca-certificates \
 && rm -rf /var/lib/apt/lists/*
RUN python3 -m venv /opt/venv && /opt/venv/bin/pip install --no-cache-dir eclipse-sumo==1.27.1
ENV PATH=/opt/venv/bin:$PATH \
    SUMO_HOME=/opt/venv/lib/python3.12/site-packages/sumo \
    DISPLAY=:0 LIBGL_ALWAYS_SOFTWARE=1
COPY start.sh /start.sh
WORKDIR /work
EXPOSE 6080
CMD ["/start.sh"]
