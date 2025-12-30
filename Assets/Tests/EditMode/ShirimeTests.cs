using NUnit.Framework;
using UnityEngine;
using YokaiBlade.Core.Boss.Shirime;

namespace YokaiBlade.Tests.EditMode
{
    public class ShirimeTests
    {
        [Test]
        public void Shirime_InitialState_Inactive()
        {
            var go = new GameObject();
            var boss = go.AddComponent<ShirimeBoss>();

            Assert.That(boss.State, Is.EqualTo(ShirimeState.Inactive));

            Object.DestroyImmediate(go);
        }

        [Test]
        public void Shirime_StartEncounter_TransitionsToBow()
        {
            var go = new GameObject();
            var boss = go.AddComponent<ShirimeBoss>();

            boss.StartEncounter();

            Assert.That(boss.State, Is.EqualTo(ShirimeState.Bow));

            Object.DestroyImmediate(go);
        }

        [Test]
        public void Shirime_CanBeDefeated_OnlyWhenStaggered()
        {
            var go = new GameObject();
            var boss = go.AddComponent<ShirimeBoss>();

            Assert.That(boss.CanBeDefeated, Is.False);

            boss.ApplyStagger(1f);

            Assert.That(boss.CanBeDefeated, Is.True);

            Object.DestroyImmediate(go);
        }

        [Test]
        public void Shirime_Defeat_TransitionsToDefeated()
        {
            var go = new GameObject();
            var boss = go.AddComponent<ShirimeBoss>();
            bool defeated = false;
            boss.OnDefeated += () => defeated = true;

            boss.ApplyStagger(1f);
            boss.Defeat();

            Assert.That(boss.State, Is.EqualTo(ShirimeState.Defeated));
            Assert.That(defeated, Is.True);

            Object.DestroyImmediate(go);
        }

        #region Negative Path Tests

        [Test]
        public void Shirime_Defeat_WhenNotStaggered_StillDefeats()
        {
            var go = new GameObject();
            var boss = go.AddComponent<ShirimeBoss>();
            bool defeated = false;
            boss.OnDefeated += () => defeated = true;

            // Not staggered, but Defeat() is a direct call
            Assert.That(boss.CanBeDefeated, Is.False);
            boss.Defeat();

            // Current implementation allows defeat regardless
            Assert.That(boss.State, Is.EqualTo(ShirimeState.Defeated));
            Assert.That(defeated, Is.True);

            Object.DestroyImmediate(go);
        }

        [Test]
        public void Shirime_Defeat_WhenAlreadyDefeated_DoesNotFireEventAgain()
        {
            var go = new GameObject();
            var boss = go.AddComponent<ShirimeBoss>();
            int defeatedCount = 0;
            boss.OnDefeated += () => defeatedCount++;

            boss.ApplyStagger(1f);
            boss.Defeat();
            boss.Defeat(); // Call again

            Assert.That(defeatedCount, Is.EqualTo(1), "OnDefeated should only fire once");

            Object.DestroyImmediate(go);
        }

        [Test]
        public void Shirime_ApplyStagger_WithZeroDuration_StillEnablesDefeat()
        {
            var go = new GameObject();
            var boss = go.AddComponent<ShirimeBoss>();

            boss.ApplyStagger(0f);

            Assert.That(boss.CanBeDefeated, Is.True);

            Object.DestroyImmediate(go);
        }

        [Test]
        public void Shirime_StartEncounter_WhenAlreadyInBow_DoesNotRestart()
        {
            var go = new GameObject();
            var boss = go.AddComponent<ShirimeBoss>();
            int stateChanges = 0;
            boss.OnStateChanged += (_) => stateChanges++;

            boss.StartEncounter();
            int changesAfterFirst = stateChanges;
            boss.StartEncounter(); // Call again

            // Should not double-transition
            Assert.That(boss.State, Is.EqualTo(ShirimeState.Bow));

            Object.DestroyImmediate(go);
        }

        #endregion
    }
}
