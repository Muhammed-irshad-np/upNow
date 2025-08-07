package com.example.upnow

import android.content.Context
import android.content.Intent
import android.media.MediaPlayer
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.util.Log
import android.view.KeyEvent
import android.view.WindowManager
import android.widget.GridLayout
import android.widget.Button
import android.widget.EditText
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.activity.OnBackPressedCallback
import kotlin.random.Random
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

class AlarmActivity : AppCompatActivity() {
    companion object {
        private const val TAG = "AlarmActivity"
        const val EXTRA_ALARM_ID = "alarm_id"
        const val EXTRA_ALARM_LABEL = "alarm_label"
        const val EXTRA_ALARM_SOUND = "alarm_sound"
    }

    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var alarmId: String? = null
    private var isAlarmActive = true // Flag to track if the alarm is still active
    private var timeUpdateHandler: Handler? = null
    private var timeRunnable: Runnable? = null
    
    // Math problem variables
    private var num1: Int = 0
    private var num2: Int = 0
    private var correctAnswer: Int = 0
    private var operatorIndex: Int = 0

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "AlarmActivity onCreate")
        
        // Set window flags to show over lock screen and keep screen on
        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
        )
        
        setContentView(R.layout.activity_alarm)
        
        // Get alarm details from intent
        alarmId = intent.getStringExtra(EXTRA_ALARM_ID) ?: "unknown"
        val alarmLabel = intent.getStringExtra(EXTRA_ALARM_LABEL) ?: "Alarm!"
        val soundName = intent.getStringExtra(EXTRA_ALARM_SOUND) ?: "alarm_sound"
        
        Log.d(TAG, "Alarm triggered - ID: $alarmId, Label: $alarmLabel, Sound: $soundName")
        
        // Set alarm title
        val titleTextView = findViewById<TextView>(R.id.alarm_title)
        titleTextView.text = alarmLabel
        
        // Set up current time display
        setupTimeDisplay()
        
        // Acquire wake lock to keep CPU running
        acquireWakeLock()
        
        // Stop any Flutter audio players that might be playing
        try {
            // Send a message to Flutter to stop any audio players
            val methodChannel = MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger, "com.example.upnow/alarm_overlay")
            methodChannel.invokeMethod("stopFlutterAudio", null)
            Log.d(TAG, "Requested Flutter to stop audio players")
        } catch (e: Exception) {
            Log.d(TAG, "Could not communicate with Flutter to stop audio: ${e.message}")
        }
        
        // Start sound and vibration
        startAlarmSound(soundName)
        startVibration()
        
        // Generate math problem
        generateMathProblem()
        
        // Set up verification button and answer input
        val verifyButton = findViewById<Button>(R.id.verify_button)
        val answerInput = findViewById<EditText>(R.id.answer_input)
        
        // Set up numpad
        setupNumpad(answerInput)
        
        verifyButton.setOnClickListener {
            val userAnswerStr = answerInput.text.toString()
            if (userAnswerStr.isNotEmpty()) {
                try {
                    val userAnswer = userAnswerStr.toInt()
                    if (userAnswer == correctAnswer) {
                        // Correct answer
                        Toast.makeText(this, "Correct! Alarm dismissed.", Toast.LENGTH_SHORT).show()
                        stopAlarmAndOpenCongratulations()
                    } else {
                        // Wrong answer
                        Toast.makeText(this, "Wrong answer, try again!", Toast.LENGTH_SHORT).show()
                        // Generate a new problem to make it more challenging
                        generateMathProblem()
                        answerInput.text.clear()
                    }
                } catch (e: NumberFormatException) {
                    Toast.makeText(this, "Please enter a valid number", Toast.LENGTH_SHORT).show()
                }
            } else {
                Toast.makeText(this, "Please enter an answer", Toast.LENGTH_SHORT).show()
            }
        }

        // Use the modern way to handle back presses
        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                // Do nothing to prevent back button from closing the activity
                Log.d(TAG, "Back button pressed, ignoring.")
                Toast.makeText(this@AlarmActivity, "Please complete the task to dismiss", Toast.LENGTH_SHORT).show()
            }
        })
    }
    
    private fun setupTimeDisplay() {
        val timeTextView = findViewById<TextView>(R.id.current_time)
        val amPmIndicator = findViewById<TextView>(R.id.am_pm_indicator)
        
        // Update time initially
        updateCurrentTime(timeTextView, amPmIndicator)
        
        // Set up a handler to update the time every minute
        timeUpdateHandler = Handler(Looper.getMainLooper())
        timeRunnable = object : Runnable {
            override fun run() {
                updateCurrentTime(timeTextView, amPmIndicator)
                timeUpdateHandler?.postDelayed(this, 60000) // Update every minute
            }
        }
        
        // Start the time updates
        timeUpdateHandler?.post(timeRunnable!!)
    }
    
    private fun updateCurrentTime(timeTextView: TextView, amPmIndicator: TextView) {
        val calendar = Calendar.getInstance()
        val timeFormat = SimpleDateFormat("h:mm", Locale.getDefault())
        val currentTime = timeFormat.format(calendar.time)
        timeTextView.text = currentTime
        
        // Update AM/PM indicator
        val isAm = calendar.get(Calendar.AM_PM) == Calendar.AM
        amPmIndicator.text = if (isAm) "AM" else "PM"
    }
    
    private fun generateMathProblem() {
        // Define operators (0: addition, 1: subtraction, 2: multiplication)
        val operators = arrayOf("+", "-", "×")
        
        // Generate random numbers and operator based on difficulty
        operatorIndex = Random.nextInt(0, 3)
        
        when (operatorIndex) {
            0 -> { // Addition
                num1 = Random.nextInt(10, 100)
                num2 = Random.nextInt(10, 100)
                correctAnswer = num1 + num2
            }
            1 -> { // Subtraction
                num1 = Random.nextInt(50, 100)
                num2 = Random.nextInt(1, 50)
                correctAnswer = num1 - num2
            }
            2 -> { // Multiplication
                num1 = Random.nextInt(3, 13)
                num2 = Random.nextInt(3, 13)
                correctAnswer = num1 * num2
            }
        }
        
        // Update UI with the new problem
        val mathProblemView = findViewById<TextView>(R.id.math_problem)
        mathProblemView.text = "$num1 ${operators[operatorIndex]} $num2 = ?"
        
        Log.d(TAG, "Generated math problem: $num1 ${operators[operatorIndex]} $num2 = $correctAnswer")
    }
    
    private fun setupNumpad(answerInput: EditText) {
        // Number buttons (0-9)
        val numberButtons = listOf(
            findViewById<Button>(R.id.num_0),
            findViewById<Button>(R.id.num_1),
            findViewById<Button>(R.id.num_2),
            findViewById<Button>(R.id.num_3),
            findViewById<Button>(R.id.num_4),
            findViewById<Button>(R.id.num_5),
            findViewById<Button>(R.id.num_6),
            findViewById<Button>(R.id.num_7),
            findViewById<Button>(R.id.num_8),
            findViewById<Button>(R.id.num_9)
        )
        
        // Set up number button listeners
        numberButtons.forEachIndexed { index, button ->
            button.setOnClickListener {
                val currentText = answerInput.text.toString()
                // Limit input to reasonable number length (max 5 digits)
                if (currentText.length < 5) {
                    answerInput.setText(currentText + index.toString())
                }
            }
        }
        
        // Backspace button
        findViewById<Button>(R.id.num_backspace).setOnClickListener {
            val currentText = answerInput.text.toString()
            if (currentText.isNotEmpty()) {
                answerInput.setText(currentText.dropLast(1))
            }
        }
        
        // Clear button
        findViewById<Button>(R.id.num_clear).setOnClickListener {
            answerInput.setText("")
        }
    }
    
    private fun acquireWakeLock() {
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "UpNow:AlarmWakeLock"
        )
        wakeLock?.acquire(10*60*1000L /*10 minutes*/)
    }
    
    private fun startAlarmSound(soundName: String) {
        try {
            Log.d(TAG, "Starting alarm sound with name: '$soundName'")
            
            // Stop any existing MediaPlayer first
            mediaPlayer?.apply {
                if (isPlaying) {
                    stop()
                }
                release()
            }
            mediaPlayer = null
            
            var soundUri: android.net.Uri? = null
            
            // Try to get resource ID for the custom sound name
            if (soundName != "alarm_sound" && soundName.isNotEmpty()) {
                // First try with the exact sound name as provided
                var resourceId = resources.getIdentifier(soundName, "raw", packageName)
                Log.d(TAG, "Looking for resource ID for '$soundName': $resourceId")
                
                // If not found, try with common sound names that might be in the raw folder
                if (resourceId == 0) {
                    val commonSounds = listOf("stardust", "simplified", "lofi")
                    for (commonSound in commonSounds) {
                        resourceId = resources.getIdentifier(commonSound, "raw", packageName)
                        Log.d(TAG, "Trying common sound '$commonSound': $resourceId")
                        if (resourceId != 0) {
                            Log.d(TAG, "Found matching sound resource: $commonSound (ID: $resourceId)")
                            break
                        }
                    }
                }
                
                if (resourceId != 0) { 
                    soundUri = android.net.Uri.parse("android.resource://$packageName/$resourceId")
                    Log.d(TAG, "Using custom sound resource: $soundName (ID: $resourceId)")
                } else {
                    Log.w(TAG, "Custom sound resource '$soundName' not found. Falling back to default.")
                }
            }
            
            // If custom sound wasn't found or wasn't specified, use default system alarm sound
            if (soundUri == null) {
                soundUri = android.provider.Settings.System.DEFAULT_ALARM_ALERT_URI
                Log.d(TAG, "Using default system alarm sound.")
            }
            
            // Create and start MediaPlayer
            mediaPlayer = MediaPlayer().apply {
                setDataSource(this@AlarmActivity, soundUri!!)
                setAudioAttributes(
                    android.media.AudioAttributes.Builder()
                        .setContentType(android.media.AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .setUsage(android.media.AudioAttributes.USAGE_ALARM)
                        .build()
                )
                isLooping = true
                prepareAsync() // Use prepareAsync for network/resource URIs
                setOnPreparedListener { 
                    start()
                    Log.d(TAG, "Alarm sound started with URI: $soundUri")
                }
                setOnErrorListener { mp, what, extra ->
                    Log.e(TAG, "MediaPlayer error: what=$what, extra=$extra. URI: $soundUri")
                    // Fallback to basic create maybe?
                    try {
                        mp.release() // Release errored player
                        mediaPlayer = MediaPlayer.create(this@AlarmActivity, android.provider.Settings.System.DEFAULT_ALARM_ALERT_URI)
                        mediaPlayer?.isLooping = true
                        mediaPlayer?.start()
                        Log.d(TAG, "Fallback sound started after error.")
                    } catch (e: Exception) {
                        Log.e(TAG, "Error starting fallback sound: ${e.message}")
                    }
                    true // Indicate error was handled
                }
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Error starting alarm sound: ${e.message}")
        }
    }
    
    private fun startVibration() {
        try {
            vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            
            // Create vibration pattern - 0 delay, 500ms on, 500ms off, repeat
            val pattern = longArrayOf(0, 500, 500)
            
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                vibrator?.vibrate(VibrationEffect.createWaveform(pattern, 0))
            } else {
                @Suppress("DEPRECATION")
                vibrator?.vibrate(pattern, 0)
            }
            Log.d(TAG, "Vibration started")
        } catch (e: Exception) {
            Log.e(TAG, "Error starting vibration: ${e.message}")
        }
    }
    
    private fun stopAlarmAndFinish() {
        isAlarmActive = false // Set flag to false when alarm is dismissed
        
        // Stop media player
        mediaPlayer?.apply {
            if (isPlaying) {
                stop()
            }
            release()
        }
        mediaPlayer = null
        
        // Stop vibration
        vibrator?.cancel()
        vibrator = null
        
        // Release wake lock
        wakeLock?.release()
        wakeLock = null
        
        // Stop time updates
        timeUpdateHandler?.removeCallbacks(timeRunnable!!)
        
        Log.d(TAG, "Alarm stopped and resources released")
        
        // Notify Flutter through broadcast (optional, implement if needed)
        val intent = Intent("com.example.upnow.ALARM_DISMISSED")
        intent.putExtra("alarm_id", alarmId)
        sendBroadcast(intent)
        
        // Finish the activity
        finish()
    }
    
    private fun stopAlarmAndOpenCongratulations() {
        isAlarmActive = false // Set flag to false when alarm is dismissed
        
        // Stop media player
        mediaPlayer?.apply {
            if (isPlaying) {
                stop()
            }
            release()
        }
        mediaPlayer = null
        
        // Stop vibration
        vibrator?.cancel()
        vibrator = null
        
        // Release wake lock
        wakeLock?.release()
        wakeLock = null
        
        // Stop time updates
        timeUpdateHandler?.removeCallbacks(timeRunnable!!)
        
        Log.d(TAG, "Alarm stopped, opening congratulations screen")
        
        // Open congratulations screen in Flutter
        MainActivity.openCongratulationsScreenStatic()
        
        // Notify Flutter through broadcast (optional, implement if needed)
        val intent = Intent("com.example.upnow.ALARM_DISMISSED")
        intent.putExtra("alarm_id", alarmId)
        sendBroadcast(intent)
        
        // Finish the activity after a short delay to allow Flutter navigation
        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
            finish()
        }, 500) // 500ms delay
    }
    
    // Prevent volume keys and other system keys from dismissing
    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        return if (keyCode == KeyEvent.KEYCODE_VOLUME_DOWN || 
                   keyCode == KeyEvent.KEYCODE_VOLUME_UP ||
                   keyCode == KeyEvent.KEYCODE_HOME ||
                   keyCode == KeyEvent.KEYCODE_POWER) {
            true // Consume the event
        } else {
            super.onKeyDown(keyCode, event)
        }
    }
    
    // Attempt to bring the activity back to front if user tries to exit via Home/Recents
    override fun onStop() {
        super.onStop()
        Log.d(TAG, "AlarmActivity onStop. isAlarmActive: $isAlarmActive")
        
        if (isAlarmActive) {
            // If the alarm hasn't been dismissed, try to bring it back
            Log.d(TAG, "Alarm still active, attempting to bring activity back to front.")
            val relaunchIntent = Intent(this, AlarmActivity::class.java).apply {
                // Add flags to reorder it to the front if it exists
                addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
            }
            startActivity(relaunchIntent)
        }
    }

    // Clean up resources if activity is destroyed
    override fun onDestroy() {
        // Stop time updates
        timeUpdateHandler?.removeCallbacks(timeRunnable!!)
        
        mediaPlayer?.release()
        vibrator?.cancel()
        wakeLock?.release()
        super.onDestroy()
    }
} 