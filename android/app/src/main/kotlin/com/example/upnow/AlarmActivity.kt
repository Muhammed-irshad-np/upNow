package com.example.upnow

import android.content.Context
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
    
    // Theme colors
    private var primaryColor: Int = android.graphics.Color.RED
    private var primaryColorLight: Int = android.graphics.Color.parseColor("#FF6659")
    private var currentDismissType: String = "math"
    private var currentRepeatType: String = "once"
    private var currentWeekdays: BooleanArray? = null
    private var currentHour: Int = -1
    private var currentMinute: Int = -1

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
        
        // Extract critical data early for propagation
        extractIntentData(intent)
        
        // Load and apply theme colors
        loadThemeColors()
        applyThemeColors()
        
        Log.d(TAG, "Alarm triggered - ID: $alarmId, Label: ${intent.getStringExtra(EXTRA_ALARM_LABEL)}, Sound: $selectedSoundName, Type: $currentDismissType")
        
        // Set alarm title
        findViewById<TextView>(R.id.alarm_title).text = intent.getStringExtra(EXTRA_ALARM_LABEL) ?: "Alarm!"
        
        // Set up current time display
        setupTimeDisplay()
        
        // Start service if not already started (Crucial: Pass all data!)
        val serviceStarted = intent.getBooleanExtra("service_started", false)
        if (!serviceStarted && alarmId != "unknown") {
            Log.d(TAG, "Starting foreground service with Dismiss Type: $currentDismissType")
            AlarmForegroundService.start(
                context = this,
                alarmId = alarmId!!,
                alarmLabel = intent.getStringExtra(EXTRA_ALARM_LABEL) ?: "Alarm!",
                soundName = selectedSoundName ?: "alarm_sound",
                hour = currentHour,
                minute = currentMinute,
                repeatType = currentRepeatType,
                weekdays = currentWeekdays,
                primaryColor = intent.getLongExtra("primaryColor", -1L).let { if (it != -1L) it else null },
                primaryColorLight = intent.getLongExtra("primaryColorLight", -1L).let { if (it != -1L) it else null },
                dismissType = currentDismissType
            )
        }
        
        // Setup UI based on dismiss type
        refreshUI()
        
        // Use the modern way to handle back presses
        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                // Do nothing to prevent back button from closing the activity
                Log.d(TAG, "Back button pressed, ignoring.")
                Toast.makeText(this@AlarmActivity, "Please complete the task to dismiss", Toast.LENGTH_SHORT).show()
            }
        })
    }

    private fun extractIntentData(intent: Intent) {
        alarmId = intent.getStringExtra(EXTRA_ALARM_ID) ?: "unknown"
        selectedSoundName = intent.getStringExtra(EXTRA_ALARM_SOUND) ?: "alarm_sound"
        currentDismissType = intent.getStringExtra("dismissType") ?: "math"
        currentRepeatType = intent.getStringExtra("repeatType") ?: "once"
        currentWeekdays = intent.getBooleanArrayExtra("weekdays")
        currentHour = intent.getIntExtra("hour", -1)
        currentMinute = intent.getIntExtra("minute", -1)
        
        val intentPrimary = intent.getLongExtra("primaryColor", -1L)
        val intentPrimaryLight = intent.getLongExtra("primaryColorLight", -1L)
        if (intentPrimary != -1L) primaryColor = intentPrimary.toInt()
        if (intentPrimaryLight != -1L) primaryColorLight = intentPrimaryLight.toInt()
    }

    private fun refreshUI() {
        Log.d(TAG, "Refreshing UI for Dismiss Type: $currentDismissType")
        if (currentDismissType == "typing" || currentDismissType == "text") {
            setupTypeTextDismiss()
        } else {
            setupMathDismiss()
        }
    }
    
    private fun loadThemeColors() {
        // Try to get from intent first
        val intentPrimary = intent.getLongExtra("primaryColor", -1L)
        val intentPrimaryLight = intent.getLongExtra("primaryColorLight", -1L)
        
        if (intentPrimary != -1L && intentPrimaryLight != -1L) {
            primaryColor = intentPrimary.toInt()
            primaryColorLight = intentPrimaryLight.toInt()
            Log.d(TAG, "Theme colors loaded from intent")
        } else {
            // Fallback to SharedPreferences
            val prefs = getSharedPreferences("com.example.upnow.ThemePrefs", Context.MODE_PRIVATE)
            val storedPrimary = prefs.getLong("primaryColor", -1L)
            val storedPrimaryLight = prefs.getLong("primaryColorLight", -1L)
            
            if (storedPrimary != -1L && storedPrimaryLight != -1L) {
                primaryColor = storedPrimary.toInt()
                primaryColorLight = storedPrimaryLight.toInt()
                Log.d(TAG, "Theme colors loaded from SharedPreferences")
            } else {
                Log.d(TAG, "Using default theme colors (Red)")
            }
        }
    }
    
    private fun applyThemeColors() {
        try {
            // Apply to AM/PM indicator
            val amPmIndicator = findViewById<TextView>(R.id.am_pm_indicator)
            amPmIndicator.setTextColor(primaryColor)
            
            // Apply to numpad buttons (Backspace and Clear)
            val backspaceButton = findViewById<Button>(R.id.num_backspace)
            val clearButton = findViewById<Button>(R.id.num_clear)
            
            backspaceButton.setBackgroundColor(primaryColor)
            clearButton.setBackgroundColor(primaryColor)
            
            // Apply to verify button (Gradient)
            val verifyButton = findViewById<Button>(R.id.verify_button)
            val gradientDrawable = android.graphics.drawable.GradientDrawable(
                android.graphics.drawable.GradientDrawable.Orientation.TL_BR,
                intArrayOf(primaryColor, primaryColorLight)
            )
            gradientDrawable.cornerRadius = 12f * resources.displayMetrics.density // 12dp
            verifyButton.background = gradientDrawable
            
            Log.d(TAG, "Theme colors applied to UI")
        } catch (e: Exception) {
            Log.e(TAG, "Error applying theme colors: ${e.message}")
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        
        extractIntentData(intent)
        Log.d(TAG, "onNewIntent - Updated data, Type: $currentDismissType")
        
        refreshUI()
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
            Log.d(TAG, "Alarm still active, attempting to bring activity back to front with Type: $currentDismissType")
            val relaunchIntent = Intent(this, AlarmActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
                putExtra(EXTRA_ALARM_ID, alarmId)
                putExtra(EXTRA_ALARM_LABEL, intent.getStringExtra(EXTRA_ALARM_LABEL))
                putExtra(EXTRA_ALARM_SOUND, selectedSoundName)
                putExtra("dismissType", currentDismissType)
                putExtra("primaryColor", primaryColor.toLong())
                putExtra("primaryColorLight", primaryColorLight.toLong())
                putExtra("repeatType", currentRepeatType)
                putExtra("weekdays", currentWeekdays)
                putExtra("hour", currentHour)
                putExtra("minute", currentMinute)
                putExtra("service_started", true)
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

    private fun setupMathDismiss() {
        // Show math card, hide type text card
        findViewById<androidx.cardview.widget.CardView>(R.id.math_card).visibility = android.view.View.VISIBLE
        findViewById<androidx.cardview.widget.CardView>(R.id.type_text_card).visibility = android.view.View.GONE
        
        generateMathProblem()
        
        val verifyButton = findViewById<Button>(R.id.verify_button)
        val answerInput = findViewById<EditText>(R.id.answer_input)
        
        setupNumpad(answerInput)
        
        verifyButton.setOnClickListener {
            val userAnswerStr = answerInput.text.toString()
            if (userAnswerStr.isNotEmpty()) {
                try {
                    val userAnswer = userAnswerStr.toInt()
                    if (userAnswer == correctAnswer) {
                        Toast.makeText(this, "Correct! Alarm dismissed.", Toast.LENGTH_SHORT).show()
                        stopAlarmAndOpenCongratulations()
                    } else {
                        Toast.makeText(this, "Wrong answer, try again!", Toast.LENGTH_SHORT).show()
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

    private fun setupTypeTextDismiss() {
        // Hide math card, show type text card
        findViewById<androidx.cardview.widget.CardView>(R.id.math_card).visibility = android.view.View.GONE
        findViewById<androidx.cardview.widget.CardView>(R.id.type_text_card).visibility = android.view.View.VISIBLE
        
        val targetPhraseView = findViewById<TextView>(R.id.target_phrase)
        val phraseInput = findViewById<EditText>(R.id.phrase_input)
        val verifyButton = findViewById<Button>(R.id.verify_text_button)
        
        // Random phrases
        val phrases = listOf(
            "I am awake",
            "I will achieve my goals",
            "Today is a new day",
            "Rise and shine",
            "Focus on the positive",
            "Action cures fear",
            "Discipline equals freedom"
        )
        val targetPhrase = phrases.random()
        targetPhraseView.text = targetPhrase
        
        // Request focus to show keyboard
        phraseInput.requestFocus()
        // Note: Soft keyboard might not show automatically on lock screen without extra flags or user interaction
        
        verifyButton.setOnClickListener {
            val userPhrase = phraseInput.text.toString().trim()
            if (userPhrase.equals(targetPhrase, ignoreCase = true)) {
                Toast.makeText(this, "Correct! Alarm dismissed.", Toast.LENGTH_SHORT).show()
                stopAlarmAndOpenCongratulations()
            } else {
                Toast.makeText(this, "Incorrect phrase. Try again!", Toast.LENGTH_SHORT).show()
                phraseInput.text.clear()
            }
        }
    }
} 