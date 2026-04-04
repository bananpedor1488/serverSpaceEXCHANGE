package com.bananjemmy.data.cache

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import com.bananjemmy.data.cache.dao.ChatDao
import com.bananjemmy.data.cache.dao.IdentityDao
import com.bananjemmy.data.cache.dao.MessageDao
import com.bananjemmy.data.cache.entity.CachedChat
import com.bananjemmy.data.cache.entity.CachedIdentity
import com.bananjemmy.data.cache.entity.CachedMessage

@Database(
    entities = [
        CachedIdentity::class,
        CachedChat::class,
        CachedMessage::class
    ],
    version = 1,
    exportSchema = false
)
abstract class JemmyDatabase : RoomDatabase() {
    abstract fun identityDao(): IdentityDao
    abstract fun chatDao(): ChatDao
    abstract fun messageDao(): MessageDao
    
    companion object {
        @Volatile
        private var INSTANCE: JemmyDatabase? = null
        
        fun getDatabase(context: Context): JemmyDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    JemmyDatabase::class.java,
                    "jemmy_database"
                ).build()
                INSTANCE = instance
                instance
            }
        }
    }
}
