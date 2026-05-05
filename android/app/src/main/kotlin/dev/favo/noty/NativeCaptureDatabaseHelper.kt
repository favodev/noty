package dev.favo.noty

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import org.json.JSONObject

class NativeCaptureDatabaseHelper(context: Context) :
    SQLiteOpenHelper(context, DATABASE_NAME, null, DATABASE_VERSION) {

    companion object {
        private const val DATABASE_NAME = "noty_native_capture.db"
        private const val DATABASE_VERSION = 1
        const val TABLE_NAME = "pending_notifications"
        const val COLUMN_ID = "id"
        const val COLUMN_PAYLOAD = "payload"
        const val COLUMN_CREATED_AT = "created_at"
    }

    override fun onCreate(db: SQLiteDatabase) {
        val createTable = """
            CREATE TABLE $TABLE_NAME (
                $COLUMN_ID INTEGER PRIMARY KEY AUTOINCREMENT,
                $COLUMN_PAYLOAD TEXT NOT NULL,
                $COLUMN_CREATED_AT INTEGER NOT NULL
            )
        """.trimIndent()
        db.execSQL(createTable)
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        db.execSQL("DROP TABLE IF EXISTS $TABLE_NAME")
        onCreate(db)
    }

    fun append(payload: Map<String, Any?>) {
        val db = this.writableDatabase
        val item = JSONObject()
        payload.forEach { (key, value) ->
            item.put(key, value ?: JSONObject.NULL)
        }

        val values = ContentValues().apply {
            put(COLUMN_PAYLOAD, item.toString())
            put(COLUMN_CREATED_AT, System.currentTimeMillis())
        }

        db.insert(TABLE_NAME, null, values)
        db.close()
    }

    fun drain(): List<Map<String, Any?>> {
        val result = mutableListOf<Map<String, Any?>>()
        val db = this.writableDatabase

        db.beginTransaction()
        try {
            val cursor = db.query(
                TABLE_NAME,
                arrayOf(COLUMN_ID, COLUMN_PAYLOAD),
                null,
                null,
                null,
                null,
                "$COLUMN_CREATED_AT ASC"
            )

            val idsToDelete = mutableListOf<String>()

            while (cursor.moveToNext()) {
                val id = cursor.getLong(cursor.getColumnIndexOrThrow(COLUMN_ID))
                val payloadStr = cursor.getString(cursor.getColumnIndexOrThrow(COLUMN_PAYLOAD))
                
                try {
                    val json = JSONObject(payloadStr)
                    result.add(jsonToMap(json))
                    idsToDelete.add(id.toString())
                } catch (e: Exception) {
                    // Si el JSON esta corrupto, lo borramos igual para no trabar la cola
                    idsToDelete.add(id.toString())
                }
            }
            cursor.close()

            if (idsToDelete.isNotEmpty()) {
                // SQLite tiene un limite de variables en IN (?), tipicamente 999.
                // Para simplificar y siendo seguro dentro de la transaccion, borramos todo
                // ya que leimos todo (a menos que sigan entrando mientras leemos,
                // borrar por ID es mas seguro que DELETE FROM sin WHERE).
                val batchSize = 900
                for (i in 0 until idsToDelete.size step batchSize) {
                    val batch = idsToDelete.subList(i, minOf(i + batchSize, idsToDelete.size))
                    val args = batch.joinToString(",") { "?" }
                    db.delete(TABLE_NAME, "$COLUMN_ID IN ($args)", batch.toTypedArray())
                }
            }

            db.setTransactionSuccessful()
        } finally {
            db.endTransaction()
            db.close()
        }

        return result
    }

    private fun jsonToMap(json: JSONObject): Map<String, Any?> {
        val map = mutableMapOf<String, Any?>()
        val keys = json.keys()

        while (keys.hasNext()) {
            val key = keys.next()
            val value = json.get(key)
            map[key] = if (value == JSONObject.NULL) null else value
        }

        return map
    }
}
