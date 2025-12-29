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
    }
}
