# Room creates generated database implementations using reflection.
# R8 must preserve their zero-argument constructors.
-keep class * extends androidx.room.RoomDatabase {
    <init>();
}

# WorkManager creates InputMerger implementations using reflection.
-keep class * extends androidx.work.InputMerger {
    <init>();
}

# Preserve WorkManager generated database implementation.
-keep class androidx.work.impl.WorkDatabase_Impl {
    <init>();
}
