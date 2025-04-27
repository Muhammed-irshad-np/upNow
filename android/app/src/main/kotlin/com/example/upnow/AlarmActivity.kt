package com.example.upnow

import android.content.Context
import android.content.Intent
import android.media.MediaPlayer
import android.os.Bundle
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.util.Log
import android.view.KeyEvent
import android.view.WindowManager
import android.widget.Button
import android.widget.EditText
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import kotlin.random.Random

class AlarmActivity : AppCompatActivity() {
    companion object {
        private const val TAG = "AlarmActivity"
        const val EXTRA_ALARM_ID = "alarm_id"
        const val EXTRA_ALARM_LABEL = "alarm_label"
    }

    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var alarmId: String? = null
    
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
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_FULLSCREEN
        )
        
        setContentView(R.layout.activity_alarm)
        
        // Get alarm details from intent
        alarmId = intent.getStringExtra(EXTRA_ALARM_ID) ?: "unknown"
        val alarmLabel = intent.getStringExtra(EXTRA_ALARM_LABEL) ?: "Alarm!"
        
        Log.d(TAG, "Alarm triggered - ID: $alarmId, Label: $alarmLabel")
        
        // Set alarm title
        val titleTextView = findViewById<TextView>(R.id.alarm_title)
        titleTextView.text = alarmLabel
        
        // Acquire wake lock to keep CPU running
        acquireWakeLock()
        
        // Start sound and vibration
        startAlarmSound()
        startVibration()
        
        // Generate math problem
        generateMathProblem()
        
        // Set up verification button
        val verifyButton = findViewById<Button>(R.id.verify_button)
        val answerInput = findViewById<EditText>(R.id.answer_input)
        
        verifyButton.setOnClickListener {
            val userAnswerStr = answerInput.text.toString()
            if (userAnswerStr.isNotEmpty()) {
                try {
                    val userAnswer = userAnswerStr.toInt()
                    if (userAnswer == correctAnswer) {
                        // Correct answer
                        Toast.makeText(this, "Correct! Alarm dismissed.", Toast.LENGTH_SHORT).show()
                        stopAlarmAndFinish()
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
    
    private fun acquireWakeLock() {
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "UpNow:AlarmWakeLock"
        )
        wakeLock?.acquire(10*60*1000L /*10 minutes*/)
    }
    
    private fun startAlarmSound() {
        try {
            // Using a default alarm sound - you can replace with custom sound from raw resources
            mediaPlayer = MediaPlayer.create(this, android.provider.Settings.System.DEFAULT_ALARM_ALERT_URI)
            mediaPlayer?.isLooping = true
            mediaPlayer?.start()
            Log.d(TAG, "Alarm sound started")
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
        
        Log.d(TAG, "Alarm stopped and resources released")
        
        // Notify Flutter through broadcast (optional, implement if needed)
        val intent = Intent("com.example.upnow.ALARM_DISMISSED")
        intent.putExtra("alarm_id", alarmId)
        sendBroadcast(intent)
        
        // Finish the activity
        finish()
    }
    
    // Prevent back button from dismissing the activity
    override fun onBackPressed() {
        // Do nothing, preventing back button dismiss
        Toast.makeText(this, "Please complete the task to dismiss", Toast.LENGTH_SHORT).show()
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
    
    // Clean up resources if activity is destroyed
    override fun onDestroy() {
        mediaPlayer?.release()
        vibrator?.cancel()
        wakeLock?.release()
        super.onDestroy()
    }
} 