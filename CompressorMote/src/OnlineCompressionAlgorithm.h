#ifndef ONLINE_COMPRESSION_ALGORITHM_H
#define ONLINE_COMPRESSION_ALGORITHM_H

typedef enum {
  OCA_ERR_INVALID_FILE = 40,
  OCA_ERR_BUFFER_OVERFLOW = 50,
} CompressionError;

enum {
  COMPRESSION_TYPE_NONE = 0,
  COMPRESSION_TYPE_RUN_LENGTH = 1,
  COMPRESSION_TYPE_BLOCK_TRUNCATION = 2,
  COMPRESSION_TYPE_ROSS = 3
};

#endif /* ONLINE_COMPRESSION_ALGORITHM_H */
