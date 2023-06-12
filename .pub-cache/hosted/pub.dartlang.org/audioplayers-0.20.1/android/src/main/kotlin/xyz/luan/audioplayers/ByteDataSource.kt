package xyz.luan.audioplayers

import android.media.MediaDataSource

class ByteDataSource(
        private val data: ByteArray
) : MediaDataSource() {
    @Synchronized
    override fun getSize(): Long {
        return data.size.toLong()
    }

    @Synchronized
    override fun close() = Unit

    @Synchronized
    override fun readAt(position: Long, buffer: ByteArray, offset: Int, size: Int): Int {
        if (position >= data.size) {
            return -1
        }

        var remainingSize = size
        if (position + remainingSize > data.size) {
            remainingSize -= position.toInt() + remainingSize - data.size
        }
        System.arraycopy(data, position.toInt(), buffer, offset, remainingSize)
        return remainingSize
    }

}
