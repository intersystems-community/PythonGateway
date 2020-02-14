FROM intersystemscommunity/irispy:latest

USER root

RUN pip install jupyter && pip install $ISC_PACKAGE_INSTALLDIR/dev/python/irisnative-1.0.0-cp34-abi3-linux_x86_64.whl

USER irisowner

COPY --chown=irisowner ./jupyter/*.py /jupyter/
COPY --chown=irisowner ./jupyter/*.sh /

RUN echo -e "\r\nc.MLContentsManager.namespace = 'PYTHON'" >>  /jupyter/jupyter_notebook_config.py

HEALTHCHECK --interval=5s CMD /irisHealth.sh || exit 1