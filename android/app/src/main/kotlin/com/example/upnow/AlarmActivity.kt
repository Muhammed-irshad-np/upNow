package com.example.upnow

import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
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
import androidx.core.app.NotificationManagerCompat
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

    private var alarmId: String? = null
    private var isAlarmActive = true // Flag to track if the alarm is still active
    private var timeUpdateHandler: Handler? = null
    private var timeRunnable: Runnable? = null
    private var selectedSoundName: String? = null
    
    // Math problem variables
    private var num1: Int = 0
    private var num2: Int = 0
    private var correctAnswer: Int = 0
    private var operatorIndex: Int = 0

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "AlarmActivity onCreate")

        setShowWhenLocked(true)
        setTurnScreenOn(true)
        
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
        selectedSoundName = soundName
        
        Log.d(TAG, "Alarm triggered - ID: $alarmId, Label: $alarmLabel, Sound: $soundName")
        
        // Set alarm title
        val titleTextView = findViewById<TextView>(R.id.alarm_title)
        titleTextView.text = alarmLabel
        
        // Set up current time display
        setupTimeDisplay()
        
        val repeatType = intent.getStringExtra("repeatType") ?: "once"
        val weekdays = intent.getBooleanArrayExtra("weekdays")

        if (alarmId != null && alarmId != "unknown") {
            AlarmForegroundService.start(
                this,
                alarmId!!,
                alarmLabel,
                soundName,
                intent.getIntExtra("hour", -1),
                intent.getIntExtra("minute", -1),
                repeatType,
                weekdays
            )
        }
        
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

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        if (intent == null) return
        setIntent(intent)
        // Keep track of the sound name if a new intent provides it
        intent.getStringExtra(EXTRA_ALARM_SOUND)?.let {
            selectedSoundName = it
            Log.d(TAG, "Updated selectedSoundName from new intent: $it")
        }
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
    
    private fun stopAlarmAndFinish() {
        isAlarmActive = false // Set flag to false when alarm is dismissed
        alarmId?.let {
            NotificationManagerCompat.from(this).cancel(it.hashCode())
            AlarmForegroundService.stop(this, it)
        }

        timeRunnable?.let { runnable ->
            timeUpdateHandler?.removeCallbacks(runnable)
        }

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
        alarmId?.let {
            NotificationManagerCompat.from(this).cancel(it.hashCode())
            AlarmForegroundService.stop(this, it)
        }

        timeRunnable?.let { runnable ->
            timeUpdateHandler?.removeCallbacks(runnable)
        }

        Log.d(TAG, "Alarm stopped, opening congratulations screen")
        
        // Attempt to open congratulations screen via running Flutter instance (if available)
        MainActivity.openCongratulationsScreenStatic()
        
        // Also launch MainActivity with an extra so that if the app is terminated, it will start
        // and then navigate to the congratulations screen once Flutter is ready.
        try {
            val mainIntent = Intent(this, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                putExtra("open_congratulations", true)
            }
            startActivity(mainIntent)
            Log.d(TAG, "MainActivity launched with open_congratulations flag")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to launch MainActivity for congratulations: ${e.message}")
        }
        
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
                // Preserve original extras so custom sound is kept
                alarmId?.let { putExtra(EXTRA_ALARM_ID, it) }
                intent.getStringExtra(EXTRA_ALARM_LABEL)?.let { putExtra(EXTRA_ALARM_LABEL, it) }
                selectedSoundName?.let { putExtra(EXTRA_ALARM_SOUND, it) }
            }
            startActivity(relaunchIntent)
        }
    }

    // Clean up resources if activity is destroyed
    override fun onDestroy() {
        timeRunnable?.let { runnable ->
            timeUpdateHandler?.removeCallbacks(runnable)
        }
        super.onDestroy()
    }
} 