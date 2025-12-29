using NUnit.Framework;
using UnityEngine;
using YokaiBlade.Core.Input;

namespace YokaiBlade.Tests.EditMode
{
    /// <summary>
    /// Unit tests for Input System.
    ///
    /// Gate 3 Acceptance Criteria:
    /// - Deflect always wins priority when overlapping inputs
    /// - Buffered inputs replay consistently across frame rates
    /// </summary>
    public class InputSystemTests
    {
        private InputConfig _config;
        private InputBuffer _buffer;

        [SetUp]
        public void SetUp()
        {
            _config = ScriptableObject.CreateInstance<InputConfig>();
            _config.DeflectBufferWindow = 0.15f;
            _config.StrikeBufferWindow = 0.1f;
            _config.DodgeBufferWindow = 0.1f;
            _buffer = new InputBuffer(_config);
        }

        [TearDown]
        public void TearDown()
        {
            Object.DestroyImmediate(_config);
        }

        #region InputAction Priority Tests

        [Test]
        public void InputAction_Deflect_HasHighestPriority()
        {
            Assert.That(InputAction.Deflect.Priority(), Is.GreaterThan(InputAction.Strike.Priority()));
            Assert.That(InputAction.Deflect.Priority(), Is.GreaterThan(InputAction.Dodge.Priority()));
            Assert.That(InputAction.Deflect.Priority(), Is.GreaterThan(InputAction.Move.Priority()));
        }

        [Test]
        public void InputAction_Strike_HigherThanDodge()
        {
            Assert.That(InputAction.Strike.Priority(), Is.GreaterThan(InputAction.Dodge.Priority()));
        }

        [Test]
        public void InputAction_Dodge_HigherThanMove()
        {
            Assert.That(InputAction.Dodge.Priority(), Is.GreaterThan(InputAction.Move.Priority()));
        }

        [Test]
        public void InputAction_Move_CannotBuffer()
        {
            Assert.That(InputAction.Move.CanBuffer(), Is.False);
        }

        [Test]
        public void InputAction_CombatActions_CanBuffer()
        {
            Assert.That(InputAction.Deflect.CanBuffer(), Is.True);
            Assert.That(InputAction.Strike.CanBuffer(), Is.True);
            Assert.That(InputAction.Dodge.CanBuffer(), Is.True);
        }

        #endregion

        #region InputBuffer Priority Tests

        [Test]
        public void Buffer_Deflect_AlwaysWinsPriority()
        {
            float time = 0f;

            // Buffer strike first, then deflect
            _buffer.Buffer(InputAction.Strike, time);
            _buffer.Buffer(InputAction.Deflect, time);
            _buffer.Buffer(InputAction.Dodge, time);

            // Deflect should come out first
            var action = _buffer.Peek(time);
            Assert.That(action, Is.EqualTo(InputAction.Deflect));
        }

        [Test]
        public void Buffer_Deflect_WinsEvenIfBufferedLater()
        {
            float time = 0f;

            // Buffer in any order
            _buffer.Buffer(InputAction.Dodge, time);
            _buffer.Buffer(InputAction.Strike, time);
            _buffer.Buffer(InputAction.Deflect, time + 0.01f);

            // Deflect should still win
            var action = _buffer.Peek(time + 0.01f);
            Assert.That(action, Is.EqualTo(InputAction.Deflect));
        }

        [Test]
        public void Buffer_ConsumeHighestPriority_ReturnsDeflectFirst()
        {
            float time = 0f;

            _buffer.Buffer(InputAction.Strike, time);
            _buffer.Buffer(InputAction.Deflect, time);

            var first = _buffer.ConsumeHighestPriority(time);
            var second = _buffer.ConsumeHighestPriority(time);

            Assert.That(first, Is.EqualTo(InputAction.Deflect));
            Assert.That(second, Is.EqualTo(InputAction.Strike));
        }

        #endregion

        #region InputBuffer Timing Tests

        [Test]
        public void Buffer_Input_ExpiresAfterWindow()
        {
            float time = 0f;
            _buffer.Buffer(InputAction.Strike, time);

            // Should be valid immediately
            Assert.That(_buffer.HasBuffered(InputAction.Strike, time), Is.True);

            // Should expire after window
            float expiredTime = time + _config.StrikeBufferWindow + 0.01f;
            Assert.That(_buffer.HasBuffered(InputAction.Strike, expiredTime), Is.False);
        }

        [Test]
        public void Buffer_Input_ValidWithinWindow()
        {
            float time = 0f;
            _buffer.Buffer(InputAction.Strike, time);

            // Should be valid just before expiry
            float almostExpired = time + _config.StrikeBufferWindow - 0.01f;
            Assert.That(_buffer.HasBuffered(InputAction.Strike, almostExpired), Is.True);
        }

        [Test]
        public void Buffer_DuplicateAction_UpdatesTimestamp()
        {
            float time = 0f;
            _buffer.Buffer(InputAction.Strike, time);

            // Buffer same action later
            float laterTime = time + 0.05f;
            _buffer.Buffer(InputAction.Strike, laterTime);

            // Should still be valid based on new timestamp
            float checkTime = laterTime + _config.StrikeBufferWindow - 0.01f;
            Assert.That(_buffer.HasBuffered(InputAction.Strike, checkTime), Is.True);

            // Buffer should only have one entry
            Assert.That(_buffer.Count, Is.EqualTo(1));
        }

        [Test]
        public void Buffer_Clear_RemovesAllInputs()
        {
            float time = 0f;
            _buffer.Buffer(InputAction.Strike, time);
            _buffer.Buffer(InputAction.Deflect, time);
            _buffer.Buffer(InputAction.Dodge, time);

            _buffer.Clear();

            Assert.That(_buffer.Count, Is.EqualTo(0));
            Assert.That(_buffer.Peek(time), Is.EqualTo(InputAction.None));
        }

        #endregion

        #region BufferedInput Tests

        [Test]
        public void BufferedInput_IsValid_WithinWindow()
        {
            var input = new BufferedInput(InputAction.Strike, 0f, 0.1f);

            Assert.That(input.IsValid(0f), Is.True);
            Assert.That(input.IsValid(0.05f), Is.True);
            Assert.That(input.IsValid(0.1f), Is.True);
        }

        [Test]
        public void BufferedInput_IsExpired_AfterWindow()
        {
            var input = new BufferedInput(InputAction.Strike, 0f, 0.1f);

            Assert.That(input.IsExpired(0.11f), Is.True);
            Assert.That(input.IsExpired(1f), Is.True);
        }

        [Test]
        public void BufferedInput_TimeRemaining_Accurate()
        {
            var input = new BufferedInput(InputAction.Strike, 0f, 0.1f);

            Assert.That(input.TimeRemaining(0f), Is.EqualTo(0.1f).Within(0.001f));
            Assert.That(input.TimeRemaining(0.05f), Is.EqualTo(0.05f).Within(0.001f));
            Assert.That(input.TimeRemaining(0.1f), Is.EqualTo(0f).Within(0.001f));
            Assert.That(input.TimeRemaining(0.15f), Is.EqualTo(0f)); // Clamped to 0
        }

        #endregion

        #region PlayerState Tests

        [Test]
        public void PlayerState_Idle_CanPerformAllActions()
        {
            Assert.That(PlayerState.Idle.CanPerform(InputAction.Strike), Is.True);
            Assert.That(PlayerState.Idle.CanPerform(InputAction.Deflect), Is.True);
            Assert.That(PlayerState.Idle.CanPerform(InputAction.Dodge), Is.True);
        }

        [Test]
        public void PlayerState_Attacking_CanOnlyDeflect()
        {
            Assert.That(PlayerState.Attacking.CanPerform(InputAction.Deflect), Is.True);
            Assert.That(PlayerState.Attacking.CanPerform(InputAction.Strike), Is.False);
            Assert.That(PlayerState.Attacking.CanPerform(InputAction.Dodge), Is.False);
        }

        [Test]
        public void PlayerState_Dead_CannotPerformAnyAction()
        {
            Assert.That(PlayerState.Dead.CanPerform(InputAction.Deflect), Is.False);
            Assert.That(PlayerState.Dead.CanPerform(InputAction.Strike), Is.False);
            Assert.That(PlayerState.Dead.CanPerform(InputAction.Dodge), Is.False);
        }

        [Test]
        public void PlayerState_Deflecting_CannotDeflectAgain()
        {
            Assert.That(PlayerState.Deflecting.CanPerform(InputAction.Deflect), Is.False);
        }

        [Test]
        public void PlayerState_ActionStates_ShouldBuffer()
        {
            Assert.That(PlayerState.Attacking.ShouldBuffer(), Is.True);
            Assert.That(PlayerState.Deflecting.ShouldBuffer(), Is.True);
            Assert.That(PlayerState.Dodging.ShouldBuffer(), Is.True);
            Assert.That(PlayerState.Stunned.ShouldBuffer(), Is.True);
        }

        [Test]
        public void PlayerState_Idle_ShouldNotBuffer()
        {
            Assert.That(PlayerState.Idle.ShouldBuffer(), Is.False);
            Assert.That(PlayerState.Moving.ShouldBuffer(), Is.False);
        }

        #endregion

        #region InputConfig Tests

        [Test]
        public void InputConfig_DefaultValues_AreValid()
        {
            var config = ScriptableObject.CreateInstance<InputConfig>();

            bool valid = config.Validate(out var error);

            Assert.That(valid, Is.True, error);

            Object.DestroyImmediate(config);
        }

        [Test]
        public void InputConfig_PerfectWindowLargerThanStandard_Invalid()
        {
            var config = ScriptableObject.CreateInstance<InputConfig>();
            config.PerfectDeflectWindow = 0.2f;
            config.StandardDeflectWindow = 0.1f;

            bool valid = config.Validate(out var error);

            Assert.That(valid, Is.False);
            Assert.That(error, Does.Contain("Perfect"));

            Object.DestroyImmediate(config);
        }

        [Test]
        public void InputConfig_GetBufferWindow_ReturnsCorrectValues()
        {
            Assert.That(_config.GetBufferWindow(InputAction.Deflect), Is.EqualTo(_config.DeflectBufferWindow));
            Assert.That(_config.GetBufferWindow(InputAction.Strike), Is.EqualTo(_config.StrikeBufferWindow));
            Assert.That(_config.GetBufferWindow(InputAction.Dodge), Is.EqualTo(_config.DodgeBufferWindow));
            Assert.That(_config.GetBufferWindow(InputAction.Move), Is.EqualTo(0f));
        }

        #endregion

        #region Frame Rate Independence Tests

        [Test]
        public void Buffer_SameTimestamp_SameResult_At30fps()
        {
            SimulateFrameRate(30, out var action);
            Assert.That(action, Is.EqualTo(InputAction.Deflect));
        }

        [Test]
        public void Buffer_SameTimestamp_SameResult_At60fps()
        {
            SimulateFrameRate(60, out var action);
            Assert.That(action, Is.EqualTo(InputAction.Deflect));
        }

        [Test]
        public void Buffer_SameTimestamp_SameResult_At120fps()
        {
            SimulateFrameRate(120, out var action);
            Assert.That(action, Is.EqualTo(InputAction.Deflect));
        }

        private void SimulateFrameRate(int fps, out InputAction resultAction)
        {
            float deltaTime = 1f / fps;
            float time = 0f;

            var buffer = new InputBuffer(_config);

            // Simulate input at specific times
            buffer.Buffer(InputAction.Strike, 0.01f);
            buffer.Buffer(InputAction.Deflect, 0.02f);
            buffer.Buffer(InputAction.Dodge, 0.03f);

            // Simulate fixed update steps
            for (int i = 0; i < 10; i++)
            {
                time += deltaTime;
            }

            // Should always get deflect regardless of frame rate
            resultAction = buffer.Peek(time);
        }

        #endregion
    }
}
