#ifndef PCFILE_SENDER_H
#define PCFILE_SENDER_H

typedef enum {
  PFS_ERR_MSG_PREPARATION_FAILED = 30,
  PFS_ERR_SEND_FAILED,
  PFS_ERR_NOT_CONNECTED
} PCFileSenderError;

#endif /* PCFILE_SENDER_H */