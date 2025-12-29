using NUnit.Framework;
using UnityEngine;
using YokaiBlade.Core.Combat;

namespace YokaiBlade.Tests.EditMode
{
    public class DeathFeedbackTests
    {
        [Test]
        public void DeathFeedbackData_StoresAttackName()
        {
            var data = new DeathFeedbackData
            {
                AttackName = "Eye Beam",
                CorrectResponse = AttackResponse.Deflect
            };

            Assert.That(data.AttackName, Is.EqualTo("Eye Beam"));
        }

        [Test]
        public void DeathFeedbackData_StoresCorrectResponse()
        {
            var data = new DeathFeedbackData
            {
                AttackName = "Fire Wave",
                CorrectResponse = AttackResponse.Dodge
            };

            Assert.That(data.CorrectResponse, Is.EqualTo(AttackResponse.Dodge));
        }

        [Test]
        public void DeathFeedbackSystem_CanBeCreated()
        {
            var go = new GameObject();
            var system = go.AddComponent<DeathFeedbackSystem>();

            Assert.That(system, Is.Not.Null);
            Assert.That(system.IsFrozen, Is.False);

            Object.DestroyImmediate(go);
        }

        [Test]
        public void DeathFeedbackData_DefaultResponse_IsNone()
        {
            var data = new DeathFeedbackData();

            Assert.That(data.CorrectResponse, Is.EqualTo(AttackResponse.None));
        }
    }
}
