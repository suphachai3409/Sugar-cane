const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');

// ใช้ db จาก mongoose
const db = mongoose.connection;

// POST /api/plots - สร้างแปลงปลูกใหม่
router.post('/', async (req, res) => {
  const { userId, plotName, plantType, waterSource, soilType, latitude, longitude, polygonPoints } = req.body; // เพิ่ม polygonPoints

  try {
    const result = await db.collection('plots').insertOne({
      userId,
      plotName,
      plantType,
      waterSource,
      soilType,
      latitude,
      longitude,
      polygonPoints: polygonPoints || [], // เพิ่มตรงนี้
      createdAt: new Date()
    });
    console.log('✅ Plot saved:', {
      _id: result.insertedId,
      userId,
      plotName,
      plantType,
      waterSource,
      soilType,
      latitude,
      longitude,
    });

    res.status(200).json({
      message: 'Plot saved successfully',
      plotId: result.insertedId
    });

  } catch (error) {
    console.error('❌ Error saving plot:', error);
    res.status(500).json({ error: 'Something went wrong' });
  }
});


// GET /api/plots/:userId - ดึงข้อมูลแปลงปลูกทั้งหมดของ user
router.get('/:userId', async (req, res) => {
  const { userId } = req.params;

  try {
    // ค้นหาด้วย userId (string ธรรมดา)
    const plots = await db.collection('plots').find({
      userId: userId
    }).sort({ createdAt: -1 }).toArray();

    console.log(`✅ Found ${plots.length} plots for userId: ${userId}`);
    res.json(plots);

  } catch (error) {
    console.error('❌ Error fetching plots:', error);
    res.status(500).json({ message: 'Error fetching plots', error: error.message });
  }
});

// DELETE /api/plots/:plotId - ลบแปลงปลูก (เผื่อต้องการใช้ในอนาคต)
router.delete('/:plotId', async (req, res) => {
  const { plotId } = req.params;

  try {
    if (!mongoose.Types.ObjectId.isValid(plotId)) {
      return res.status(400).json({ message: 'Invalid plotId format' });
    }

    const result = await db.collection('plots').deleteOne({
      _id: new mongoose.Types.ObjectId(plotId)
    });

    if (result.deletedCount === 0) {
      return res.status(404).json({ message: 'Plot not found' });
    }

    console.log(`✅ Deleted plot: ${plotId}`);
    res.json({ message: 'Plot deleted successfully' });

  } catch (error) {
    console.error('❌ Error deleting plot:', error);
    res.status(500).json({ message: 'Error deleting plot', error: error.message });
  }
});

// PUT /api/plots/:plotId - แก้ไขแปลงปลูก (เผื่อต้องการใช้ในอนาคต)
router.put('/:plotId', async (req, res) => {
  const { plotId } = req.params;
  const { plotName, plantType, waterSource, soilType, latitude, longitude, polygonPoints } = req.body; // เพิ่ม polygonPoints

  try {
    // ... (validate plotId)
    const result = await db.collection('plots').updateOne(
      { _id: new mongoose.Types.ObjectId(plotId) },
      {
        $set: {
          plotName,
          plantType,
          waterSource,
          soilType,
          latitude,
          longitude,
          polygonPoints: polygonPoints || [], // เพิ่มตรงนี้
          updatedAt: new Date()
        }
      }
    );

    if (result.matchedCount === 0) {
      return res.status(404).json({ message: 'Plot not found' });
    }

    console.log(`✅ Updated plot: ${plotId}`);
    res.json({ message: 'Plot updated successfully' });

  } catch (error) {
    console.error('❌ Error updating plot:', error);
    res.status(500).json({ message: 'Error updating plot', error: error.message });
  }
});

// POST /api/plots/:plotId/recommendations - เพิ่ม recommendation
router.post('/:plotId/recommendations', async (req, res) => {
  const { plotId } = req.params;
  const { topic, date, message, images } = req.body;

  try {
    console.log('📝 Creating recommendation for plot:', plotId);

    if (!mongoose.Types.ObjectId.isValid(plotId)) {
      return res.status(400).json({ message: 'Invalid plotId format' });
    }

    const result = await db.collection('plots').updateOne(
      { _id: new mongoose.Types.ObjectId(plotId) },
      {
        $push: {
          recommendations: {
            topic,
            date,
            message,
            images: images || [],
            createdAt: new Date(),
            updatedAt: new Date()
          }
        }
      }
    );

    if (result.matchedCount === 0) {
      return res.status(404).json({ message: 'Plot not found' });
    }

    console.log('✅ Added recommendation to plot:', plotId);
    res.json({ message: 'Recommendation added successfully' });

  } catch (error) {
    console.error('❌ Error adding recommendation:', error);
    res.status(500).json({ message: 'Error adding recommendation', error: error.message });
  }
});


// GET /api/plots/:plotId/recommendations - ดึง recommendations ทั้งหมดของ plot
router.get('/:plotId/recommendations', async (req, res) => {
  const { plotId } = req.params;

  try {
    if (!mongoose.Types.ObjectId.isValid(plotId)) {
      return res.status(400).json({ message: 'Invalid plotId format' });
    }

    const plot = await db.collection('plots').findOne(
      { _id: new mongoose.Types.ObjectId(plotId) },
      { projection: { recommendations: 1 } }
    );

    if (!plot) {
      return res.status(404).json({ message: 'Plot not found' });
    }

    res.json(plot.recommendations || []);
  } catch (error) {
    console.error('❌ Error fetching recommendations:', error);
    res.status(500).json({ message: 'Error fetching recommendations', error: error.message });
  }
});
// GET /api/plots/:plotId/recommendations/:topic
router.get('/:plotId/recommendations/:topic', async (req, res) => {
  const { plotId, topic } = req.params;

  try {
    if (!mongoose.Types.ObjectId.isValid(plotId)) {
      return res.status(400).json({ message: 'Invalid plotId format' });
    }

    const plot = await db.collection('plots').findOne(
      {
        _id: new mongoose.Types.ObjectId(plotId),
        'recommendations.topic': topic
      },
      {
        projection: {
          'recommendations.$': 1
        }
      }
    );

    if (!plot || !plot.recommendations || plot.recommendations.length === 0) {
      return res.status(404).json({ message: 'Recommendation not found' });
    }

    res.json(plot.recommendations[0]);
  } catch (error) {
    console.error('❌ Error fetching recommendation:', error);
    res.status(500).json({ message: 'Error fetching recommendation', error: error.message });
  }
});

// PUT /api/plots/:plotId/recommendations/:topic
router.put('/:plotId/recommendations/:topic', async (req, res) => {
  const { plotId, topic } = req.params;
  const { date, message, images } = req.body;

  try {
    console.log('📝 Updating recommendation:', { plotId, topic });

    if (!mongoose.Types.ObjectId.isValid(plotId)) {
      return res.status(400).json({ message: 'Invalid plotId format' });
    }

    // Check if recommendation exists
    const existingRec = await db.collection('plots').findOne({
      _id: new mongoose.Types.ObjectId(plotId),
      'recommendations.topic': topic
    });

    if (!existingRec) {
      console.log('❌ Recommendation not found, creating new one');
      // ✅ ถ้าไม่พบ recommendation ให้สร้างใหม่
      const createResult = await db.collection('plots').updateOne(
        { _id: new mongoose.Types.ObjectId(plotId) },
        {
          $push: {
            recommendations: {
              topic,
              date,
              message,
              images: images || [],
              createdAt: new Date(),
              updatedAt: new Date()
            }
          }
        }
      );

      if (createResult.matchedCount === 0) {
        return res.status(404).json({ message: 'Plot not found' });
      }

      return res.json({ message: 'Recommendation created successfully' });
    }

    // Update existing recommendation
    const result = await db.collection('plots').updateOne(
      {
        _id: new mongoose.Types.ObjectId(plotId),
        'recommendations.topic': topic
      },
      {
        $set: {
          'recommendations.$.date': date,
          'recommendations.$.message': message,
          'recommendations.$.images': images || [],
          'recommendations.$.updatedAt': new Date()
        }
      }
    );

    if (result.matchedCount === 0) {
      return res.status(404).json({ message: 'Recommendation not found' });
    }

    res.json({ message: 'Recommendation updated successfully' });

  } catch (error) {
    console.error('❌ Error updating recommendation:', error);
    res.status(500).json({ message: 'Error updating recommendation', error: error.message });
  }
});

// DELETE /api/plots/:plotId/recommendations/:topic - ลบ recommendation และ task ที่เกี่ยวข้อง (เฉพาะ completed)
router.delete('/:plotId/recommendations/:topic', async (req, res) => {
  const { plotId, topic } = req.params;

  try {
    if (!mongoose.Types.ObjectId.isValid(plotId)) {
      return res.status(400).json({ message: 'Invalid plotId format' });
    }

    // 1. ลบ recommendation ก่อน
    const deleteRecResult = await db.collection('plots').updateOne(
      { _id: new mongoose.Types.ObjectId(plotId) },
      {
        $pull: {
          recommendations: { topic: topic }
        }
      }
    );

    if (deleteRecResult.matchedCount === 0) {
      return res.status(404).json({ message: 'Plot not found' });
    }

    // 2. ลบเฉพาะ task ที่เกี่ยวข้องและมีสถานะ completed
    const deleteTaskResult = await db.collection('plots').updateOne(
      { _id: new mongoose.Types.ObjectId(plotId) },
      {
        $pull: {
          tasks: {
            taskType: topic,
            status: 'completed' // ลบเฉพาะ task ที่ completed
          }
        }
      }
    );

    console.log(`✅ Deleted recommendation and completed tasks from plot: ${plotId}, topic: ${topic}`);
    console.log(`📊 Removed ${deleteRecResult.modifiedCount} recommendation and ${deleteTaskResult.modifiedCount} completed tasks`);

    res.json({
      message: 'Recommendation and related completed tasks deleted successfully',
      deletedRecommendations: deleteRecResult.modifiedCount,
      deletedTasks: deleteTaskResult.modifiedCount
    });
  } catch (error) {
    console.error('❌ Error deleting recommendation and tasks:', error);
    res.status(500).json({ message: 'Error deleting recommendation and tasks', error: error.message });
  }
});
// ==================== TASK RELATED ENDPOINTS ====================

// POST /api/plots/:plotId/tasks - มอบหมายงาน
router.post('/:plotId/tasks', async (req, res) => {
  const { plotId } = req.params;
  const { title, description, assignedWorkerId, dueDate, images } = req.body;

  try {
    console.log('📋 Assigning task details:', {
      plotId: plotId,
      title: title,
      assignedWorkerId: assignedWorkerId,
      dueDate: dueDate
    });

    if (!assignedWorkerId) {
      return res.status(400).json({
        success: false,
        message: 'กรุณาเลือกคนงาน'
      });
    }

    // ตรวจสอบว่ามีงานนี้ถูกมอบหมายไปแล้วหรือไม่
    const plot = await db.collection('plots').findOne(
      { _id: new mongoose.Types.ObjectId(plotId) }
    );

    if (plot && plot.tasks) {
      const existingTask = plot.tasks.find(task => task.taskType === title);
      if (existingTask) {
        return res.status(400).json({
          success: false,
          message: 'งานนี้ถูกมอบหมายไปแล้ว'
        });
      }
    }

    const newTask = {
      _id: new mongoose.Types.ObjectId(),
      taskType: title,
      description,
      assignedWorkerId: assignedWorkerId,
      dueDate,
      images: images || [],
      status: 'assigned',
      createdAt: new Date(),
      updatedAt: new Date()
    };

    const result = await db.collection('plots').updateOne(
      { _id: new mongoose.Types.ObjectId(plotId) },
      { $push: { tasks: newTask } }
    );

    if (result.matchedCount === 0) {
      return res.status(404).json({
        success: false,
        message: 'ไม่พบแปลงปลูก'
      });
    }

    console.log('✅ Task assigned successfully:', {
      plotId: plotId,
      taskId: newTask._id.toString(),
      workerId: newTask.assignedWorkerId
    });

    res.status(201).json({
      success: true,
      message: 'มอบหมายงานสำเร็จ',
      task: {
        _id: newTask._id.toString(),
        taskType: newTask.taskType,
        assignedWorkerId: newTask.assignedWorkerId
      }
    });
  } catch (error) {
    console.error('❌ Error assigning task:', error);
    res.status(500).json({
      success: false,
      message: 'มอบหมายงานไปแล้ว'
    });
  }
});

// GET /api/plots/tasks/:userId - ดึงงานของคนงาน (ใช้ userId)
router.get('/tasks/:userId', async (req, res) => {
  const { userId } = req.params;

  try {
    console.log('🔍 Fetching tasks for user:', userId);

    // 1. หา worker จาก userId (แปลง userId เป็น ObjectId ก่อน)
    const worker = await db.collection('workers').findOne({
      userId: new mongoose.Types.ObjectId(userId)  // ✅ แปลงเป็น ObjectId
    });

    if (!worker) {
      console.log('❌ No worker found for userId:', userId);
      return res.status(200).json([]);
    }

    const workerId = worker._id.toString();
    console.log('✅ Converted userId to workerId:', userId, '→', workerId);

    // 2. ค้นหางานทั้งหมดที่ assignedWorkerId ตรงกับ workerId
    const allPlots = await db.collection('plots').find({}).toArray();
    const tasks = [];

    allPlots.forEach(plot => {
      if (plot.tasks && Array.isArray(plot.tasks)) {
        plot.tasks.forEach(task => {
          // ตรวจสอบว่า assignedWorkerId ตรงกับ workerId
          if (task.assignedWorkerId && task.assignedWorkerId.toString() === workerId) {
            console.log('✅ Found matching task:', {
              taskType: task.taskType,
              assignedTo: task.assignedWorkerId,
              expected: workerId
            });

            tasks.push({
              plotId: plot._id.toString(),
              taskId: task._id.toString(),
              taskType: task.taskType,
              description: task.description,
              assignedWorkerId: task.assignedWorkerId,
              dueDate: task.dueDate,
              status: task.status,
              images: task.images || []
            });
          }
        });
      }
    });

    console.log(`✅ Found ${tasks.length} tasks for user: ${userId}`);
    res.status(200).json(tasks);

  } catch (error) {
    console.error('❌ Error fetching tasks:', error);
    res.status(500).json({ error: error.message });
  }
});

// PUT /api/plots/:plotId/tasks/:taskId/status - อัปเดตสถานะงาน
router.put('/:plotId/tasks/:taskId/status', async (req, res) => {
  const { plotId, taskId } = req.params;
  const { status, completedAt } = req.body;

  try {
    const updateData = {
      'tasks.$.status': status,
      'tasks.$.updatedAt': new Date()
    };

    if (completedAt) {
      updateData['tasks.$.completedAt'] = new Date(completedAt);
    }

    const result = await db.collection('plots').updateOne(
      {
        _id: new mongoose.Types.ObjectId(plotId),
        'tasks._id': new mongoose.Types.ObjectId(taskId)
      },
      { $set: updateData }
    );

    if (result.matchedCount === 0) {
      return res.status(404).json({
        success: false,
        message: 'ไม่พบงาน'
      });
    }

    res.json({
      success: true,
      message: 'อัปเดตสถานะงานสำเร็จ'
    });
  } catch (error) {
    console.error('❌ Error updating task status:', error);
    res.status(500).json({
      success: false,
      message: 'เกิดข้อผิดพลาดในการอัปเดตสถานะงาน',
      error: error.message
    });
  }
});

// ==================== DEBUG ENDPOINTS ====================

// GET /api/plots/debug/tasks-for-user/:userId - สำหรับ debug
router.get('/debug/tasks-for-user/:userId', async (req, res) => {
  const { userId } = req.params;

  try {
    console.log('🐛 DEBUG: Checking tasks for user:', userId);

    // 1. หา worker
    const worker = await db.collection('workers').findOne({ userId: userId });
    console.log('🐛 Worker found:', worker);

    if (!worker) {
      return res.json({ error: 'No worker found' });
    }

    const workerId = worker._id.toString();
    console.log('🐛 Worker ID:', workerId);

    // 2. หางานทั้งหมดในระบบ
    const allPlots = await db.collection('plots').find({}).toArray();
    const tasks = [];

    allPlots.forEach(plot => {
      if (plot.tasks && plot.tasks.length > 0) {
        plot.tasks.forEach(task => {
          if (task.assignedWorkerId && task.assignedWorkerId.toString() === workerId) {
            tasks.push(task);
          }
        });
      }
    });

    res.json({
      userId: userId,
      workerId: workerId,
      totalTasksFound: tasks.length,
      tasks: tasks
    });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET /api/plots/owner/:userId - ดึงข้อมูลเจ้าของจากคนงานหรือลูกไร่
router.get('/owner/:userId', async (req, res) => {
  const { userId } = req.params;

  try {
    console.log(`🔍 Finding owner for userId: ${userId}`);

    const userObjectId = new mongoose.Types.ObjectId(userId);

    // 1. ลองหาใน collection workers ก่อน
    const worker = await db.collection('workers').findOne({
      userId: userObjectId
    });

    if (worker && worker.ownerId) {
      console.log('✅ Found worker with owner:', {
        userId: worker.userId,
        ownerId: worker.ownerId
      });

      return res.json({
        success: true,
        ownerId: worker.ownerId.toString(),
        userType: 'worker'
      });
    }

    // 2. ถ้าไม่ใช่ worker ลองหาใน collection farmers
    const farmer = await db.collection('farmers').findOne({
      userId: userObjectId
    });

    if (farmer && farmer.ownerId) {
      console.log('✅ Found farmer with owner:', {
        userId: farmer.userId,
        ownerId: farmer.ownerId
      });

      return res.json({
        success: true,
        ownerId: farmer.ownerId.toString(),
        userType: 'farmer'
      });
    }

    console.log('❌ No worker or farmer found with this userId');
    return res.status(404).json({
      success: false,
      message: 'ไม่พบข้อมูลคนงานหรือลูกไร่สำหรับ userId นี้'
    });

  } catch (error) {
    console.error('❌ Error fetching owner data:', error);

    if (error.name === 'CastError') {
      return res.status(400).json({
        success: false,
        message: 'รูปแบบ userId ไม่ถูกต้อง'
      });
    }

    res.status(500).json({
      success: false,
      message: 'เกิดข้อผิดพลาดในการดึงข้อมูล',
      error: error.message
    });
  }
});


// GET /api/plots/by-owner/:ownerId - ดึงแปลงปลูกตาม ownerId
router.get('/by-owner/:ownerId', async (req, res) => {
  const { ownerId } = req.params;

  try {
    console.log(`🔍 Finding plots for ownerId: ${ownerId}`);

    const plots = await db.collection('plots').find({
      userId: ownerId
    }).sort({ createdAt: -1 }).toArray();

    console.log(`✅ Found ${plots.length} plots for ownerId: ${ownerId}`);
    res.json(plots);

  } catch (error) {
    console.error('❌ Error fetching plots by owner:', error);
    res.status(500).json({
      message: 'Error fetching plots',
      error: error.message
    });
  }
});

// GET /api/plots/count/:userId - นับจำนวนแปลงปลูกของ user
router.get('/count/:userId', async (req, res) => {
  const { userId } = req.params;

  try {
    const count = await db.collection('plots').countDocuments({
      userId: userId
    });

    console.log(`✅ Plot count for userId ${userId}: ${count}`);
    res.json({ count });

  } catch (error) {
    console.error('❌ Error counting plots:', error);
    res.status(500).json({ message: 'Error counting plots', error: error.message });
  }
});
// DEBUG: ตรวจสอบข้อมูล workers
router.get('/debug/workers/:workerId', async (req, res) => {
  const { workerId } = req.params;

  try {
    console.log('🐛 DEBUG: Checking worker data for:', workerId);

    const worker = await db.collection('workers').findOne({
      userId: workerId
    });

    if (!worker) {
      return res.json({
        found: false,
        message: 'No worker found with this userId'
      });
    }

    // ตรวจสอบว่ามีแปลงปลูกของ ownerId หรือไม่
    const plots = await db.collection('plots').find({
      userId: worker.ownerId ? worker.ownerId.toString() : 'invalid'
    }).toArray();

    res.json({
      found: true,
      worker: {
        userId: worker.userId,
        ownerId: worker.ownerId ? worker.ownerId.toString() : null,
        ownerName: worker.ownerName,
        hasOwnerId: !!worker.ownerId
      },
      plotsCount: plots.length,
      plots: plots.map(p => ({ plotName: p.plotName, userId: p.userId }))
    });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
// POST /api/plots/create-worker - สร้างข้อมูล worker อัตโนมัติ
router.post('/create-worker', async (req, res) => {
  const { workerUserId, ownerUserId, ownerName } = req.body;

  try {
    console.log('🛠️ Creating worker data:', { workerUserId, ownerUserId, ownerName });

    // สร้างข้อมูล worker
    const result = await db.collection('workers').insertOne({
      userId: workerUserId,
      ownerId: new mongoose.Types.ObjectId(ownerUserId),
      ownerName: ownerName || 'เจ้าของ',
      createdAt: new Date(),
      updatedAt: new Date()
    });

    console.log('✅ Worker created successfully:', result.insertedId);

    res.json({
      success: true,
      message: 'สร้างข้อมูลคนงานสำเร็จ',
      workerId: result.insertedId
    });

  } catch (error) {
    console.error('❌ Error creating worker:', error);
    res.status(500).json({
      success: false,
      message: 'เกิดข้อผิดพลาดในการสร้างข้อมูลคนงาน',
      error: error.message
    });
  }
});
// ==================== OTHER ENDPOINTS ====================
// (คงไว้แค่ endpoints จำเป็น อื่นๆ ลบออก)

module.exports = router;