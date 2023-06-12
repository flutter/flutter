package xyz.luan.audioplayers

import android.media.MediaDataSource
import android.os.Build
import androidx.annotation.RequiresApi

@RequiresApi(Build.VERSION_CODES.M)
class ByteDataSource(
    private val data: ByteArray
) : MediaDataSource() {
    @Synchronized
    override fun getSize(): Long = data.size.toLong()

    @Synchronized
    override fun close() = Unit

    @Synchronized
    override fun readAt(position: Long, buffer: ByteArray, offset: Int, size: Int): Int {
        if (position >= data.size) {
            return -1
        }

        val remainingSize = computeRemainingSize(size, position)
        System.arraycopy(data, position.toInt(), buffer, offset, remainingSize)
        return remainingSize
    }

    private fun computeRemainingSize(size: Int, position: Long): Int {
        var remainingSize = size.toLong()
        if (position + remainingSize > data.size) {
            remainingSize -= position + remainingSize - data.size
        }
        return remainingSize.toInt()
    }

}
