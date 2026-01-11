import logging


class NoNodeJSWarningFilter(logging.Filter):
    def filter(self, record):  # type: ignore
        return (
            "Could not determine jupyterlab build status without nodejs"
            not in record.getMessage()
        )


logging.getLogger("LabApp").addFilter(NoNodeJSWarningFilter())
